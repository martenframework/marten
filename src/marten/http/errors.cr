module Marten
  module HTTP
    module Errors
      # Represents an error raised when a not found response (404) should be returned by the server.
      #
      # This error can be raised in order to indicate to the Marten server that a not found response (404) should be
      # returned to the client.
      class NotFound < Exception; end

      # Represents an error raised a permission denied response (403) should be returned by the server.
      #
      # This error can be raised in order to indicate to the Marten server that a permission denied response (403)
      # should be returned to the client.
      class PermissionDenied < Exception; end

      # Represents an error raised when a suspicious operation is identified.
      #
      # This exception is raised when a user has performed an operation that should be considered suspicious because it
      # can have security implications. Such exception results in a bad request response sent to the client.
      class SuspiciousOperation < Exception; end

      # Represents an error raised when the host specified in the request doesn't match the list of allowed hosts.
      #
      # Marten has to be explictely configured to serve a list of allowed hosts. This is to mitigate HTTP Host header
      # attacks.
      class UnexpectedHost < SuspiciousOperation; end

      # Represents an error raised when too many parameters are received for a given request.
      #
      # This excepion is raised when too many parameters (such as GET or POST parameters) are received for a specific
      # request. This is to to prevent large requests that could be used in the context of DOS attacks.
      class TooManyParametersReceived < SuspiciousOperation; end

      # Represents an error raised when a condition is not met on a particular request, eg. because a middleware was not
      # applied as expected.
      class UnmetRequestCondition < Exception; end
    end
  end
end
