module Marten
  module DB
    module SQL
      module Predicate
        abstract class Base
          class_getter predicate_name : String = ""

          def self.predicate_name(name : String?)
            @@predicate_name = name
          end

          def initialize(@left_operand : Field::Base, @right_operand : Field::Any)
          end

          def to_sql(connection : Connection::Base)
            lhs_sql = @left_operand.id
            rhs_sql = connection.operator_for(self.class.predicate_name) % "%s"
            params = [@left_operand.to_db(@right_operand)]
            { "%s %s" % [lhs_sql, rhs_sql], params }
          end
        end
      end
    end
  end
end
