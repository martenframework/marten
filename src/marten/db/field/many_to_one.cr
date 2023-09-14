module Marten
  module DB
    module Field
      class ManyToOne < Base
        getter on_delete

        def initialize(
          @id : ::String,
          @relation_name : ::String,
          @to : Model.class,
          @primary_key = false,
          @foreign_key = true,
          @blank = false,
          @null = false,
          @unique = false,
          @index = true,
          @db_column = nil,
          @related : Nil | ::String | Symbol = nil,
          on_delete : ::String | Symbol = :do_nothing
        )
          @related = @related.try(&.to_s)
          @on_delete = Deletion::Strategy.parse(on_delete.to_s)
        end

        def default
          # No-op
        end

        def from_db(value) : Marten::DB::Field::ReferenceDBTypes
          case value
          when Marten::DB::Field::ReferenceDBTypes
            value
          when ::UUID
            value.hexstring
          else
            raise_unexpected_field_value(value)
          end
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Marten::DB::Field::ReferenceDBTypes
          from_db(result_set.read(Marten::DB::Field::ReferenceDBTypes | ::UUID))
        end

        # Returns a boolean indicating whether the column is a foreign key.
        def foreign_key?
          @foreign_key
        end

        def related_model
          @to
        end

        def relation?
          true
        end

        def relation_name
          @relation_name
        end

        def to_column : Management::Column::Base?
          Management::Column::Reference.new(
            name: db_column!,
            to_table: @to.db_table,
            to_column: @to.pk_field.db_column!,
            primary_key: primary_key?,
            foreign_key: foreign_key?,
            null: null?,
            unique: unique?,
            index: index?
          )
        end

        def to_db(value) : ::DB::Any
          @to.pk_field.to_db(value).as(ReferenceDBTypes)
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || kwargs[:to].is_a?(NilLiteral) %}
            {% raise "A related model must be specified for many to one fields ('to' option)" %}
          {% end %}

          {% if !kwargs.is_a?(NilLiteral) && kwargs[:unique].is_a?(BoolLiteral) && kwargs[:unique] %}
            {% raise "Many to one fields cannot set 'unique: true' (use 'one_to_one' fields instead)" %}
          {% end %}
        end

        # :nodoc:
        macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
          {% relation_attribute_name = field_id %}
          {% field_id = (field_id.stringify + "_id").id %}
          {% related_model_klass = kwargs[:to] %}

          # Registers a field corresponding to the related object ID to the considered model class. For example, if an
          # 'author' many to one field is defined in a 'post' model, an 'author_id' many to one field will actually be
          # created for the model at hand.

          class ::{{ model_klass }}
            register_field(
              {{ @type }}.new(
                {{ field_id.stringify }},
                {{ relation_attribute_name.stringify }},
                {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %}
              )
            )

            {% if !model_klass.resolve.abstract? %}
              # Getter and setter methods for the raw related object ID and the plain related object need to be created.

              {% if related_model_klass.stringify == "self" %}
                {% related_model_klass = model_klass %}
              {% end %}

              @[Marten::DB::Model::Table::FieldInstanceVariable(
                field_klass: {{ @type }},
                field_kwargs: {{ kwargs }},
                field_type: {{ field_ann[:exposed_type] }},
                relation_name: {{ relation_attribute_name }},
                related_model: {{ related_model_klass }},
                model_klass: {{ model_klass }}
              )]
              @{{ field_id }} : {{ field_ann[:exposed_type] }}?

              @{{ relation_attribute_name }} : {{ related_model_klass }}?

              def {{ field_id }} : {{ field_ann[:exposed_type] }}?
                @{{ field_id }}
              end

              def {{ field_id }}!
                @{{ field_id }}.not_nil!
              end

              def {{ field_id }}?
                self.class.get_field({{ field_id.stringify }}).getter_value?({{ field_id }})
              end

              def {{ field_id }}=(related_id : {{ field_ann[:exposed_type] }}?)
                @{{ field_id }} = related_id
                @{{ relation_attribute_name }} = nil
              end

              def {{ relation_attribute_name }} : {{ related_model_klass }}?
                @{{ relation_attribute_name }} ||= begin
                  {{ related_model_klass }}.get(pk: @{{ field_id }})
                end
              end

              def {{ relation_attribute_name }}! : {{ related_model_klass }}
                {{ relation_attribute_name }}.not_nil!
              end

              def {{ relation_attribute_name }}?
                !{{ relation_attribute_name }}.nil?
              end

              def {{ relation_attribute_name }}=(related_object : {{ related_model_klass }}?)
                @{{ field_id }} = if related_object.nil?
                  nil
                else
                  related_object.class.pk_field.to_db(related_object.pk)
                end

                @{{ relation_attribute_name }} = related_object
              end
            {% end %}
          end

          {% if !model_klass.resolve.abstract? %}
            {% related_field_name = kwargs[:related] %}

            # Register the reverse relation.

            ::{{ related_model_klass }}.register_reverse_relation(
              Marten::DB::ReverseRelation.new(
                {% if !related_field_name.is_a?(NilLiteral) %}
                  {{ related_field_name.id.stringify }},
                {% else %}
                  nil,
                {% end %}
                ::{{ model_klass }},
                {{ field_id.stringify }}
              )
            )

            # Configure reverse relation methods if applicable (when the 'related' option is set).

            {% if !related_field_name.is_a?(NilLiteral) %}
              class ::{{ model_klass }}
                macro finished
                  class ::{{ related_model_klass }}
                    @[Marten::DB::Model::Table::RelationInstanceVariable]
                    @_reverse_m2o_{{ related_field_name.id }} : Marten::DB::Query::RelatedSet({{ model_klass }})?

                    def {{ related_field_name.id }}
                      @_reverse_m2o_{{ related_field_name.id }} ||=
                        Marten::DB::Query::RelatedSet({{ model_klass }}).new(self, {{ field_id.stringify }})
                    end
                  end
                end
              end
            {% end %}
          {% end %}
        end
      end
    end
  end
end
