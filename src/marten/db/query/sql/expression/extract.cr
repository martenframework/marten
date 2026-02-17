module Marten
  module DB
    module Query
      module SQL
        module Expression
          # Represents a SQL EXTRACT expression for extracting parts from date/time fields
          # This provides a database-agnostic way to extract year, month, day, hour, minute, second
          class Extract
            getter field : Field::Base
            getter extract_part : String

            def initialize(@field : Field::Base, @extract_part : String)
            end

            def to_sql_left(connection : Connection::Base, alias_prefix : String) : String
              col = "#{alias_prefix}.#{@field.db_column}"
              transform = connection.operator_for(@extract_part)
              transform.sub("%s", col)
            end
          end
        end
      end
    end
  end
end
