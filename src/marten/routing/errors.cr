module Marten
  module Routing
    module Errors
      class NoResolveMatch < Exception; end

      class NoReverseMatch < Exception; end

      class InvalidRuleName < Exception; end

      class InvalidRulePath < Exception; end

      class InvalidParameterName < Exception; end

      class UnknownParameterType < Exception; end
    end
  end
end
