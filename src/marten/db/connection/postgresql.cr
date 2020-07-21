module Marten
  module DB
    module Connection
      class PostgreSQL < Base
        def left_operand_for(id : String, predicate) : String
          transformation = PREDICATE_TO_LEFT_OPERAND_TRANSFORMATION_MAPPING.fetch(predicate, nil)
          transformation.nil? ? id : (transformation % id)
        end

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

        private PREDICATE_TO_LEFT_OPERAND_TRANSFORMATION_MAPPING = {
          "icontains" => "UPPER(%s)",
          "iexact" => "UPPER(%s)",
          "istartswith" => "UPPER(%s)",
        }

        private PREDICATE_TO_OPERATOR_MAPPING = {
          "contains" => "LIKE %s",
          "exact" => "= %s",
          "icontains" => "LIKE UPPER(%s)",
          "iexact" => "LIKE UPPER(%s)",
          "istartswith" => "LIKE UPPER(%s)",
          "startswith" => "LIKE %s",
        }
      end
    end
  end
end
