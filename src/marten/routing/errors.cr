module Marten
  module Routing
    module Errors
      class NoResolveMatch < Exception; end
      class InvalidParameterName < Exception; end
      class UnknownParameterType < Exception; end
    end
  end
end
