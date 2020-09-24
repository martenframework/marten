module Marten
  module CLI
    class Command
      class Test < Base
        help "Display all the routes of the application."

        @verbose : Bool = false

        @bar = "test"
        @arg1 : String?
        @arg2 : String?

        def setup
          on_option(:v, :verbose, "Enable verbose mode (show route parameter details)") { @verbose = true }
          on_option(:bar, "Bar!") { @bar = "bar" }
          on_argument(:arg1, "First argument") { |v| @arg1 = v }
          on_argument(:arg2, "First argument") { |v| @arg2 = v }
        end

        def run
          puts "Test!"
        end
      end
    end
  end
end
