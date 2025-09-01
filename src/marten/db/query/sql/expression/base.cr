module Marten
  module DB
    module Query
      module SQL
        module Expression
          abstract class Base
            getter field : Field::Base

            def initialize(@field : Field::Base)
            end

            # Returns the SQL representation for use in WHERE clauses
            abstract def to_sql_left(connection : Connection::Base, alias_prefix : String) : String
          end
        end
      end
    end
  end
end
