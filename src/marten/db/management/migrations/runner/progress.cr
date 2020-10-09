module Marten
  module DB
    module Management
      module Migrations
        class Runner
          class Progress
            getter migration
            getter type

            def initialize(@type : ProgressType, @migration : Migration? = nil)
            end
          end
        end
      end
    end
  end
end
