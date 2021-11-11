module Marten
  module CLI
    class Manage
      module Command
        class Version < Base
          help "Show the Marten version."

          def run
            print("Marten #{Marten::VERSION}")
          end
        end
      end
    end
  end
end
