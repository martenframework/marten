module Marten
  module DB
    module SQL
      module Predicate
        abstract class Base
          class_getter predicate_name : String = ""

          def self.predicate_name(name : String?)
            @@predicate_name = name
          end

          def initialize(@left_operand : Field::Base, @right_operand : Field::Any, @alias_prefix : String)
          end

          def to_sql(connection : Connection::Base)
            sql_left_operand = connection.left_operand_for(
              "#{@alias_prefix}.#{@left_operand.db_column}",
              self.class.predicate_name
            )
            sql_right_operand = connection.operator_for(self.class.predicate_name) % "%s"
            {"%s %s" % [sql_left_operand, sql_right_operand], sql_params(connection)}
          end

          private def sql_params(connection)
            [sql_right_operand_param(connection)]
          end

          private def sql_right_operand_param(_connection)
            @left_operand.to_db(@right_operand)
          end
        end
      end
    end
  end
end
