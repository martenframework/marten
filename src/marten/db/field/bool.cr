module Marten
  module DB
    module Field
      class Bool < Base
        def from_db_result_set(result_set : ::DB::ResultSet) : ::Bool?
          [true, "true", 1, "1", "yes"].includes?(result_set.read)
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
