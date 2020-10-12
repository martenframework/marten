module Marten
  module DB
    module Management
      module Migrations
        class Runner
          class PreInitialNode
            getter app_label

            def initialize(@app_label : String)
            end
          end
        end
      end
    end
  end
end
