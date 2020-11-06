module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class IEndsWith < Base
            predicate_name "iendswith"

            private def sql_right_operand_param(connection)
              "%#{connection.sanitize_like_pattern(super.to_s)}"
            end
          end
        end
      end
    end
  end
end
