module Marten
  module Handlers
    module Errors
      # Represents an error that is raised when a specific handler or associated attribute is improperly configured.
      class ImproperlyConfigured < Exception; end
    end
  end
end
