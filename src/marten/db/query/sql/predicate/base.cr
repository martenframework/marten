module Marten
  module DB
    module Query
      module SQL
        module Predicate
          abstract class Base
            class_getter predicate_name : String = ""

            def self.predicate_name(name : String?)
              @@predicate_name = name
            end

            def initialize(
              @left_operand : Field::Base,
              @right_operand : Field::Any | Array(Field::Any),
              @alias_prefix : String
            )
            end

            def to_sql(connection : Connection::Base)
              {"%s %s" % [sql_left_operand(connection), sql_right_operand(connection)], sql_params(connection)}
            end

            private def sql_left_operand(connection)
              connection.left_operand_for(
                "#{@alias_prefix}.#{@left_operand.db_column}",
                self.class.predicate_name
              )
            end

            private def sql_params(connection)
              [sql_right_operand_param(connection)].flatten
            end

            private def sql_right_operand(connection)
              connection.operator_for(self.class.predicate_name) % "%s"
            end

            private def sql_right_operand_param(_connection) : ::DB::Any
              @left_operand.to_db(@right_operand.as(Field::Any))
            end
          end
        end
      end
    end
  end
end
