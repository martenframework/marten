module Marten
  abstract class Schema
    module Errors
      # Represents an error raised when a field value cannot be processed because it doesn't have the expected type.
      # This can happen when initializing schema objects using unexpected values and types.
      class UnexpectedFieldValue < ArgumentError; end

      # Represents an error raised when an inexistent field is requested for a specific schema.
      class UnknownField < Exception; end
    end
  end
end
