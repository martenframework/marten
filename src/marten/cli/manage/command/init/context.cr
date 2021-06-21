module Marten
  module CLI
    class Manage
      module Command
        class Init < Base
          class Context
            property dir : String
            property name : String

            def initialize(
              @dir = "example",
              @name = "example"
            )
            end

            def expanded_dir
              Path.new(dir).expand
            end
          end
        end
      end
    end
  end
end
