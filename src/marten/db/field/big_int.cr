module Marten
  module DB
    module Field
      class BigInt < Base
        def from_db_result_set(result_set : ::DB::ResultSet) : Int64?
          result_set.read(Int32 | Int64 | Nil).try(&.to_i64)
        end

        def to_column : Migration::Column::Base
          Migration::Column::BigInt.new(
            db_column,
            primary_key?,
            null?,
            unique?,
            db_index?
          )
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when Int64
            value
          when Int8, Int16, Int32
            value.as(Int8 | Int16 | Int32).to_i64
          else
            raise_unexpected_field_value(value)
          end
        end
      end
    end
  end
end
