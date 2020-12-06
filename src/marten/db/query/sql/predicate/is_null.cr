module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class IsNull < Base
            predicate_name "isnull"

            def to_sql(connection : Connection::Base)
              sql = @right_operand ? "%s IS NULL" : "%s IS NOT NULL"
              {sql % [sql_left_operand(connection)], [] of String}
            end
          end
        end
      end
    end
  end
end
