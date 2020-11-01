module Marten
  module DB
    module Management
      class Statement
        abstract class Reference
          def rename_table(old_name : String, new_name : String)
          end
        end
      end
    end
  end
end
