module Marten
  module DB
    module Management
      class Statement
        class IndexName < Reference
          def initialize(
            @index_name_proc : Proc(String, Array(String), String, String),
            @table : String,
            @columns : Array(String),
            @suffix : String = ""
          )
          end

          def to_s
            @index_name_proc.call(@table, @columns, @suffix)
          end
        end
      end
    end
  end
end
