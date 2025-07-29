module Marten
  module DB
    module Query
      module SQL
        module Expression
          class Extract < Base

            def initialize(@field : Field::Base, @predicate_name : String); end

            def to_sql_left(connection : Connection::Base, alias_prefix : String) : String
              col = "#{alias_prefix}.#{@field.db_column}"
              transform = connection.operator_for(@predicate_name)
              transform.sub("%s", col)
            end
          end
        end
      end
    end
  end
end
