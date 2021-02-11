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
          @editable = true,
          @db_column = nil,
          @db_index = false
        )
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : ::Bool?
          val = result_set.read
          null? && val.nil? ? nil : [true, "true", 1, "1", "yes"].includes?(val)
        end

        def to_column : Management::Column::Base
          Management::Column::Bool.new(
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
