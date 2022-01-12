module Marten
  module DB
    module Field
      class Int < Base
        getter default

        def initialize(
          @id : ::String,
          @primary_key = false,
          @auto = false,
          @default : Int32? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil
        )
        end

        # Returns `true` if the field is automatically incremented.
        def auto?
          @auto
        end

        def from_db(value) : Int32 | Int64 | Nil
          case value
          when Int32 | Nil
            value.as?(Int32 | Nil)
          when Int64
            value.as?(Int64).try(&.to_i32)
          else
            raise_unexpected_field_value(value)
          end
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Int32 | Int64 | Nil
          from_db(result_set.read(Int32 | Int64 | Nil))
        end

        def perform_validation(record : Model)
          super unless auto?
        end

        def to_column : Management::Column::Base?
          Management::Column::Int.new(
            db_column!,
            primary_key: primary_key?,
            auto: auto?,
            null: null?,
            unique: unique?,
            index: index?,
            default: to_db(default)
          )
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when Int32
            value
          when Int8, Int16, Int64
            value.as(Int8 | Int16 | Int64).to_i32
          when ::String
            value.to_i32? || raise_unexpected_field_value(value)
          else
            raise_unexpected_field_value(value)
          end
        end
      end
    end
  end
end
