module Marten
  module Apps
    module Errors
      # Represents an error raised when an application cannot be found for a specific class.
      class AppNotFound < Exception; end

      # Represents an error raised when an application config is invalid.
      class InvalidAppConfig < Exception; end
    end
  end
end
