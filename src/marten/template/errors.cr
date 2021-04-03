module Marten
  module Template
    module Errors
      # Represents an error raised if a syntax error is detected when parsing a template.
      class InvalidSyntax < Exception; end

      # Represents an error raised when a template cannot be found.
      class TemplateNotFound < Exception; end
    end
  end
end
