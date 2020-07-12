module Marten
  module DB
    module Connection
      class SQLite < Base
        def operator_for(predicate) : String
          PREDICATE_TO_OPERATOR_MAPPING[predicate]
        end

        def parameter_id_for_ordered_argument(number : Int) : String
          "?"
        end

        def quote_char : Char
          '"'
        end

        def scheme : String
          "sqlite3"
        end

        private PREDICATE_TO_OPERATOR_MAPPING = {
          "exact" => "= %s",
          "iexact" => "LIKE %s ESCAPE '\\'"
        }
      end
    end
  end
end
