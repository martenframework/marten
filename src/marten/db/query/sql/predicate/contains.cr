module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class Contains < Base
            predicate_name "contains"

            private def sql_right_operand_param(connection)
              "%#{connection.sanitize_like_pattern(super.to_s)}%"
            end
          end
        end
      end
    end
  end
end
