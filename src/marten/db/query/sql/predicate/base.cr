module Marten
  module DB
    module Query
      module SQL
        module Predicate
          abstract class Base
            alias LeftOperand = Annotation::Base | Field::Base | SQL::Expression::Base

            class_getter predicate_name : String = ""

            getter alias_prefix

            setter alias_prefix

            def self.predicate_name(name : String?)
              @@predicate_name = name
            end

            def initialize(
              @left_operand : LeftOperand,
              @right_operand : Field::Any | Array(Field::Any),
              @alias_prefix : String,
            )
            end

            def to_sql(connection : Connection::Base)
              {"%s %s" % [sql_left_operand(connection), sql_right_operand(connection)], sql_params(connection)}
            end

            protected getter left_operand

            private def sql_left_operand(connection)
              rendered = case @left_operand
                         when Annotation::Base
                           @left_operand.as(Annotation::Base).to_sql(with_alias: false)
                         when SQL::Expression::Base
                           @left_operand.as(SQL::Expression::Base).to_sql_left(connection, @alias_prefix)
                         else
                           "#{@alias_prefix}.#{@left_operand.as(Field::Base).db_column}"
                         end
              connection.left_operand_for(
                rendered,
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
              case @left_operand
              when Annotation::Base
                @left_operand.as(Annotation::Base).field.to_db(@right_operand.as(Field::Any))
              when SQL::Expression::Base
                value = @right_operand.as(Field::Any)
                case value
                when ::DB::Any
                  value
                else
                  value.to_s
                end
              else
                @left_operand.as(Field::Base).to_db(@right_operand.as(Field::Any))
              end
            end
          end
        end
      end
    end
  end
end
