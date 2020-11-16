module Marten
  module DB
    module Management
      class Statement
        abstract class Reference
          def references_column?(table : String, column : String?)
            false
          end

          def references_table?(name : String?)
            false
          end

          def rename_column(table : String, old_name : String, new_name : String)
          end

          def rename_table(old_name : String, new_name : String)
          end
        end
      end
    end
  end
end
