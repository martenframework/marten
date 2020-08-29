module Marten
  module DB
    module Field
      class ForeignKey < Base
        include IsBuiltInField

        def initialize(
          @id : ::String,
          @relation_name : ::String,
          @to : Model.class,
          @primary_key = false,
          @blank = false,
          @null = false,
          @unique = false,
          @editable = true,
          @name = nil,
          @db_column = nil
        )
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Int32 | Int64 | Nil
          result_set.read(Int32 | Int64 | Nil)
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

        protected def related_model
          @to
        end

        protected def relation?
          true
        end

        protected def relation_name
          @relation_name
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || kwargs[:to].is_a?(NilLiteral) %}
            {% raise "A related model must be specified for foreign keys ('to' option)" %}
          {% end %}
        end

        # :nodoc:
        macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
          {% relation_attribute_name = field_id %}
          {% field_id = (field_id.stringify + "_id").id %}

          # Registers a field corresponding to the related object ID to the considered model class. For example, if an
          # 'author' foreign key is defined in a 'post' model, an 'author_id' foreign key field will actually be created
          # for the model at hand.

          class ::{{ model_klass }}
            @@fields[{{ field_id.stringify }}] = {{ @type }}.new(
              {{ field_id.stringify }},
              {{ relation_attribute_name.stringify }},
              {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %}
            )

            # Getter and setter methods for the raw related object ID and the plain related object need to be created.

            @[Marten::DB::Model::Table::FieldInstanceVariable(
              field_klass: {{ @type }},
              field_kwargs: {{ kwargs }},
              field_type: {{ field_ann[:exposed_type] }}
            )]
            @{{ field_id }} : {{ field_ann[:exposed_type] }}?

            {% related_model_klass = kwargs[:to] %}
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
              return if @{{ field_id }}.nil?
              @{{ relation_attribute_name }} ||= {{ related_model_klass }}.get(pk: @{{ field_id }})
            end

            def {{ relation_attribute_name }}! : {{ related_model_klass }}
              {{ relation_attribute_name }}.not_nil!
            end

            def {{ relation_attribute_name }}=(related_object : {{ related_model_klass }}?)
              @{{ field_id }} = related_object.try(&.id)
              @{{ relation_attribute_name }} = related_object
            end
          end
        end
      end
    end
  end
end
