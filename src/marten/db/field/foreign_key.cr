module Marten
  module DB
    module Field
      class ForeignKey < Base
        def initialize(
          @id : ::String,
          @to : Model.class,
          @primary_key = false,
          @blank = false,
          @null = false,
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
      end
    end
  end
end
