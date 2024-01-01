module Marten
  module CLI
    module Templates
      module App
        class Context
          getter label

          def initialize(@label : String)
          end

          def app_class_name : String
            "#{module_name}::App"
          end

          def module_name : String
            label.split("_").map(&.capitalize).join
          end
        end
      end
    end
  end
end
