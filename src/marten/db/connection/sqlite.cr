module Marten
  module DB
    module Connection
      class SQLite < Base
        def left_operand_for(id : String, _predicate) : String
          id
        end

        def operator_for(predicate) : String
          PREDICATE_TO_OPERATOR_MAPPING[predicate]
        end

        def parameter_id_for_ordered_argument(number : Int) : String
          "?"
        end

        def quote_char : Char
          '"'
        end

        def sanitize_like_pattern(pattern : String) : String
          pattern.gsub("%", "\%").gsub("_", "\_")
        end

        def scheme : String
          "sqlite3"
        end

        private PREDICATE_TO_OPERATOR_MAPPING = {
          "contains" => "LIKE %s ESCAPE '\\'",
          "exact" => "= %s",
          "icontains" => "LIKE %s ESCAPE '\\'",
          "iexact" => "LIKE %s ESCAPE '\\'",
        }
      end
    end
  end
end
