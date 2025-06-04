module Marten
  module Routing
    # A route match, corresponding to a specific handler plus the extracted route parameters.
    struct Match
      getter handler
      getter kwargs
      getter rule : Marten::Routing::Rule::Path

      def initialize(@handler : Marten::Handlers::Base.class, @rule : Marten::Routing::Rule::Path, @kwargs = MatchParameters.new)
      end
    end
  end
end
