module Marten
  module Template
    # A template safe string.
    #
    # A safe string is simply an object wrapping a string ; it indicates that the underlying string is "safe" and that
    # it should not be automatically escaped at rendering time.
    struct SafeString
      forward_missing_to @string

      def initialize(@string : String)
      end

      def to_s(io)
        @string.to_s(io)
      end

      def ==(other)
        @string == other
      end
    end
  end
end
