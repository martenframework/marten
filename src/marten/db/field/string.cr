module Marten
  module DB
    module Field
      class String < Base
        @max_size : ::Int32?

        getter max_size

        def initialize(
          @id : ::String,
          @primary_key = false,
          @blank = false,
          @null = false,
          @editable = true,
          @name = nil,
          @max_size = nil
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
          return if !value.as?(::String) || @max_size.nil?

          if value.as(::String).size > @max_size.not_nil!
            record.errors.add(id, "The maximum allowed length is #{@max_size}")
          end
        end
      end
    end
  end
end
