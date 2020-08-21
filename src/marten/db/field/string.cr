module Marten
  module DB
    module Field
      class String < Base
        include IsBuiltInField

        getter max_size

        def initialize(
          @id : ::String,
          @max_size : ::Int32,
          @primary_key = false,
          @blank = false,
          @null = false,
          @editable = true,
          @name = nil
        )
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : ::String?
          result_set.read(::String?)
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when ::String
            value
          else
            raise_unexpected_field_value(value)
          end
        end

        def empty_value?(value) : ::Bool
          case value
          when Nil
            true
          when ::String
            value.empty?
          else
            raise_unexpected_field_value(value)
          end
        end

        def validate(record, value)
          return if !value.as?(::String)

          if value.as(::String).size > @max_size
            record.errors.add(id, "The maximum allowed length is #{@max_size}")
          end
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || kwargs[:max_size].is_a?(NilLiteral) %}
            {% raise "String fields must define 'max_size' property" %}
          {% end %}
        end

        private def db_type_parameters
          {max_size: max_size}
        end
      end
    end
  end
end
