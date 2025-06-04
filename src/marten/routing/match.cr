module Marten
  module Routing
    # A route match, corresponding to a specific handler plus the extracted route parameters.
    struct Match
      getter handler
      getter kwargs
      getter rule

      def initialize(@handler : Marten::Handlers::Base.class, @kwargs = MatchParameters.new, @rule = Marten::Routing::Rule::Path.new)
      end
    end
  end
end
