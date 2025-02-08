module Marten
  module Template
    module Tag
      # Allows to escape values.
      #
      # This concern module allows to easily escape values within tags that return possibly unsafe strings.
      module CanEscapeValues
        # Escapes the given value based on the current context.
        def escape_value(value : String, context : Context) : String
          context.escape? ? HTML.escape(value) : value
        end
      end
    end
  end
end
