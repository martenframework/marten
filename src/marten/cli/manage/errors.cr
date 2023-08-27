module Marten
  module CLI
    class Manage
      module Errors
        # Represents an error raised when commands are instructed to terminate execution immediately through the use of
        # the `#exit` method and when they are being executed in an environment that explicitly disallows this (such as
        # specs).
        class Exit < Exception
          getter code

          def initialize(@code : Int32)
          end
        end
      end
    end
  end
end
