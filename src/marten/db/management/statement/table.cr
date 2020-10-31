module Marten
  module DB
    module Management
      class Statement
        class Table < Reference
          def initialize(@quote_proc : Proc(String, String), @name : String)
          end

          def to_s
            @quote_proc.call(@name)
          end
        end
      end
    end
  end
end
