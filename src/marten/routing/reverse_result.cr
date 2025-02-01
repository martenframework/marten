# file: src/marten/routing/reverser_result.cr
module Marten
  module Routing
    # Represents the outcome of calling Reverser#reverse.
    struct ReverseResult
      # Contains details about what went wrong during reverse: which
      # parameters are missing, which are extra, etc.
      struct Mismatch
        getter missing_params : Array(String)
        getter extra_params : Array(String)
        getter invalid_params : Array(Tuple(String, Parameter::Types))

        def initialize(
          @missing_params = [] of String,
          @extra_params = [] of String,
          @invalid_params = [] of Tuple(String, Parameter::Types),
        )
        end

        def empty?
          missing_params.empty? || extra_params.empty? || invalid_params.empty?
        end
      end

      getter url : String?
      getter mismatch : Mismatch?

      def initialize(@url : String)
        @mismatch = nil
      end

      def initialize(@mismatch : Mismatch)
        @url = nil
      end

      def success?
        !@url.nil?
      end
    end
  end
end
