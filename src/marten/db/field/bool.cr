module Marten
  module DB
    module Field
      class Bool < Base
        getter default

        def initialize(
          @id : ::String,
          @primary_key = false,
          @default : ::Bool? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil
        )
        end

        def from_db(value) : ::Bool?
          null? && value.nil? ? nil : [true, "true", 1, "1", "yes"].includes?(value)
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : ::Bool?
          from_db(result_set.read(::Bool | Int8 | Int16 | Int32 | Int64 | Nil | ::String))
        end

        def to_column : Management::Column::Base?
          Management::Column::Bool.new(
            db_column!,
            primary_key?,
            null?,
            unique?,
            index?,
            to_db(default)
          )
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when ::Bool
            value
          else
            raise_unexpected_field_value(value)
          end
        end
      end
    end
  end
end
