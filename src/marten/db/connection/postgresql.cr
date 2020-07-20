module Marten
  module DB
    module Connection
      class PostgreSQL < Base
        def operator_for(predicate) : String
          PREDICATE_TO_OPERATOR_MAPPING[predicate]
        end

        def parameter_id_for_ordered_argument(number : Int) : String
          "$#{number}"
        end

        def quote_char : Char
          '"'
        end

        def sanitize_like_pattern(pattern : String) : String
          pattern.gsub("%", "\%").gsub("_", "\_")
        end

        def scheme : String
          "postgres"
        end

        private PREDICATE_TO_OPERATOR_MAPPING = {
          "contains" => "LIKE %s",
          "exact" => "= %s",
          "icontains" => "LIKE %s",
          "iexact" => "LIKE %s",
        }
      end
    end
  end
end
