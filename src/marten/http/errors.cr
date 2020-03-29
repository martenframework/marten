module Marten
  module HTTP
    module Errors
      # Represents an error raised when a suspicious operation is identified.
      #
      # This exception is raised when a user has performed an operation that should be considered suspicious because it
      # can have security implications. Such exception results in a bad request response sent to the client.
      class SuspiciousOperation < Exception; end

      # Represents an error raised when too many parameters are received for a given request.
      #
      # This excepion is raised when too many parameters (such as GET or POST parameters) are received for a specific
      # request. This is to to prevent large requests that could be used in the context of DOS attacks.
      class TooManyParametersReceived < SuspiciousOperation; end
    end
  end
end
