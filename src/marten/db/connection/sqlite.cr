module Marten
  module DB
    module Connection
      class SQLite < Base
        def operator_for(predicate) : String
          PREDICATE_TO_OPERATOR_MAPPING[predicate]
        end

        def quote_char : Char
          '"'
        end

        def scheme : String
          "sqlite3"
        end

        private PREDICATE_TO_OPERATOR_MAPPING = {
          "exact" => "= %s",
        }
      end
    end
  end
end
