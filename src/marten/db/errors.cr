module Marten
  module DB
    module Errors
      # Represents an error raised when a problem is detected with a specific model field.
      class InvalidField < Exception; end

      # Represents an error raised when an inexistent field is requested for a specific model.
      class UnknownField < Exception; end
    end
  end
end
