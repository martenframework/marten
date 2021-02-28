module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class In < Base
            predicate_name "in"

            private def sql_right_operand(_connection)
              String.build do |s|
                s << "IN ( "
                s << @right_operand.as(Array(Field::Any)).join(" , ") { "%s" }
                s << " )"
              end
            end

            private def sql_right_operand_param(_connection)
              @right_operand.as(Array(Field::Any)).map { |o| @left_operand.to_db(o) }
            end
          end
        end
      end
    end
  end
end
