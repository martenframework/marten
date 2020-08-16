module Marten
  module DB
    module Field
      class Int < Base
        include IsBuiltInField

        def from_db_result_set(result_set : ::DB::ResultSet) : Int32?
          result_set.read(Int32?)
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when Int32
            value
          when Int8, Int16
            value.as(Int8 | Int16).to_i32
          else
            raise_unexpected_field_value(value)
          end
        end
      end
    end
  end
end
