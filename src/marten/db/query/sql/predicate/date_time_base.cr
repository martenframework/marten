module Marten
  module DB
    module Query
      module SQL
        module Predicate
          abstract class DateTimeBase < Base
            def to_sql(connection : Connection::Base)
              unless @left_operand.is_a?(Field::Date) || @left_operand.is_a?(Field::DateTime)
                raise Errors::UnmetQuerySetCondition.new(
                  "Predicate '#{self.class.predicate_name}' can only be used on date/datetime fields"
                )
              end

              sql = safe_format(connection.operator_for(self.class.predicate_name), sql_left_operand(connection))

              {"#{sql} = %s", sql_params(connection)}
            end

            private def safe_format(template : String, arg : String) : String
              template.sub("%s", arg)
            end

            private def sql_right_operand(connection)
              connection.operator_for(self.class.predicate_name) % "%s"
            end

            private def sql_right_operand_param(_connection)
              @right_operand.to_s
            end
          end
        end
      end
    end
  end
end
