module Marten
  module Routing
    module Errors
      # Represents an error raised when a route is not found.
      class NoResolveMatch < Exception; end

      # Represents an error raised when a route cannot be reversed.
      class NoReverseMatch < Exception; end

      # Represents an error raised when an invalid route map is defined.
      class InvalidRouteMap < Exception; end

      # Represents an error raised when an invalid route name is defined.
      class InvalidRuleName < Exception; end

      # Represents an error raised when an invalid route path is defined.
      class InvalidRulePath < Exception; end

      # Represents an error raised when an invalid route parameter is defined.
      class InvalidParameterName < Exception; end

      # Represents an error raised when an unknown parameter type is being used in a route definition.
      class UnknownParameterType < Exception; end
    end
  end
end
