module Marten
  module DB
    module Field
      class OneToMany < Base
        getter on_delete

        def initialize(
          @id : ::String,
          @relation_name : ::String,
          @to : Model.class,
          @primary_key = false,
          @blank = false,
          @null = false,
          @unique = false,
          @editable = true,
          @db_column = nil,
          @db_index = true,
          @related : Nil | ::String | Symbol = nil,
          on_delete : ::String | Symbol = :do_nothing
        )
          @related = @related.try(&.to_s)
          @on_delete = Deletion::Strategy.parse(on_delete.to_s)
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Int32 | Int64 | Nil
          result_set.read(Int32 | Int64 | Nil)
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

        def to_column : Management::Column::Base
          Management::Column::ForeignKey.new(
            name: db_column,
            to_table: @to.db_table,
            to_column: @to.pk_field.db_column,
            primary_key: primary_key?,
            null: null?,
            unique: unique?,
            index: db_index?
          )
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when Int32, Int64
            value
          when Int8, Int16
            value.as(Int8 | Int16).to_i32
          else
            raise_unexpected_field_value(value)
          end
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || kwargs[:to].is_a?(NilLiteral) %}
            {% raise "A related model must be specified for one to many fields ('to' option)" %}
          {% end %}

          {% if !kwargs.is_a?(NilLiteral) && kwargs[:unique].is_a?(BoolLiteral) && kwargs[:unique] %}
            {% raise "One to many fields cannot set 'unique: true' (use 'one_to_one' fields instead)" %}
          {% end %}
        end

        # :nodoc:
        macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
          {% relation_attribute_name = field_id %}
          {% field_id = (field_id.stringify + "_id").id %}

          # Registers a field corresponding to the related object ID to the considered model class. For example, if an
          # 'author' one to many field is defined in a 'post' model, an 'author_id' one to many field will actually be
          # created for the model at hand.

          class ::{{ model_klass }}
            register_field(
              {{ @type }}.new(
                {{ field_id.stringify }},
                {{ relation_attribute_name.stringify }},
                {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %}
              )
            )

            # Getter and setter methods for the raw related object ID and the plain related object need to be created.

            {% related_model_klass = kwargs[:to] %}

            @[Marten::DB::Model::Table::FieldInstanceVariable(
              field_klass: {{ @type }},
              field_kwargs: {{ kwargs }},
              field_type: {{ field_ann[:exposed_type] }},
              relation_name: {{ relation_attribute_name }},
              related_model: {{ related_model_klass }}
            )]
            @{{ field_id }} : {{ field_ann[:exposed_type] }}?

            @{{ relation_attribute_name }} : {{ related_model_klass }}?

            def {{ field_id }} : {{ field_ann[:exposed_type] }}?
              @{{ field_id }}
            end

            def {{ field_id }}!
              @{{ field_id }}.not_nil!
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

            def {{ relation_attribute_name }}=(related_object : {{ related_model_klass }}?)
              @{{ field_id }} = related_object.try(&.id)
              @{{ relation_attribute_name }} = related_object
            end
          end

          # Register the reverse relation.

          ::{{ related_model_klass }}.register_reverse_relation(
            Marten::DB::ReverseRelation.new(::{{ model_klass }}, {{ field_id.stringify }})
          )

          # Configure reverse relation methods if applicable (when the 'related' option is set).

          {% related_field_name = kwargs[:related] %}

          {% if !related_field_name.nil? %}
          class ::{{ model_klass }}
            macro finished
              class ::{{ related_model_klass }}
                def {{ related_field_name.id }}
                  Marten::DB::Query::RelatedSet({{ model_klass }}).new(self, {{ field_id.stringify }})
                end
              end
            end
          end
          {% end %}
        end
      end
    end
  end
end
