require "./operator/*"

module Marten
  module Template
    class Condition
      module Token
        # Registry of the supported operator condition tokens.
        module Operator
          # Returns the token corresponding to a given operator representation or `nil` if not found.
          def self.for(operator_id)
            REGISTRY.fetch(operator_id, nil)
          end

          private REGISTRY = {
            "||"  => Operator::Or,
            "&&"  => Operator::And,
            "not" => Operator::Not,
            "in"  => Operator::In,
            "=="  => Operator::Equal,
            "!="  => Operator::NotEqual,
            ">"   => Operator::GreaterThan,
            ">="  => Operator::GreaterThanOrEqual,
            "<"   => Operator::LessThan,
            "<="  => Operator::LessThanOrEqual,
          }
        end
      end
    end
  end
end
