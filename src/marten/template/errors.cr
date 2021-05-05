module Marten
  module Template
    module Errors
      # Represents an error raised if a syntax error is detected when parsing a template.
      class InvalidSyntax < Exception
        property filepath : String? = nil
        property source : String? = nil
        property token : Parser::Token? = nil
      end

      # Represents an error raised when a template cannot be found.
      class TemplateNotFound < Exception; end

      # Represents an error raised when an unknown variable or an unknown variable attribute is being accessed.
      class UnknownVariable < Exception; end

      # Represents an error raised when a template value is used in a context that is not allowed by its underlying
      # type.
      class UnsupportedType < Exception; end

      # Represents an error raised when an attempt to prepare a context value from an unsupported object is made.
      class UnsupportedValue < Exception; end
    end
  end
end
