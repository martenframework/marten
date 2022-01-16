module Marten
  abstract class Schema
    module Errors
      # Represents an error raised when an inexistent field is requested for a specific schema.
      class UnknownField < Exception; end
    end
  end
end
