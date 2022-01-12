module Marten
  module DB
    module Field
      class Float < Base
        getter default

        def initialize(
          @id : ::String,
          @primary_key = false,
          @default : Float64? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil
        )
        end

        def from_db(value) : Float64?
          case value
          when Nil
            value.as?(Nil)
          when Float64
            value.as?(Float64)
          else
            raise_unexpected_field_value(value)
          end
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Float64?
          from_db(result_set.read(Float64 | Nil).try(&.to_f64))
        end

        def to_column : Management::Column::Base?
          Management::Column::Float.new(
            db_column!,
            primary_key: primary_key?,
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
          when Float64
            value
          when Float32, Int8, Int16, Int32, Int64
            value.as(Float32 | Int8 | Int16 | Int32 | Int64).to_f64
          else
            raise_unexpected_field_value(value)
          end
        end
      end
    end
  end
end
