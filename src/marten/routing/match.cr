module Marten
  module Routing
    # A route match, corresponding to a specific handler plus the extracted route parameters.
    struct Match
      getter handler
      getter kwargs

      def initialize(@handler : Marten::Handlers::Base.class, @kwargs = MatchParameters.new)
      end
    end
  end
end
