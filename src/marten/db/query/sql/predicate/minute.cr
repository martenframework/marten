module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class Minute < DateTimeBase
            predicate_name "minute"

            private def sql_right_operand_param(_connection)
              "%02d" % @right_operand.to_s.to_i
            end
          end
        end
      end
    end
  end
end
