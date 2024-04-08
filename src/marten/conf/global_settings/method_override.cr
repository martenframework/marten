module Marten
  module Conf
    class GlobalSettings
      # Allows to configure middleware overriding-related settings.
      class MethodOverride
        @input_name : String = "_method"
        @allowed_methods : Array(String) = ["DELETE", "PATCH", "PUT"]

        # Returns an array containing the HTTP methods allowed for override.
        getter allowed_methods

        # Returns the name of the input field used to signal method overrides (e.g., in forms).
        getter input_name

        # Sets the name of the input field used for method overrides.
        setter input_name

        # Sets the array of HTTP methods that are allowed for override.
        def allowed_methods=(methods)
          @allowed_methods = methods.map(&.upcase)
        end
      end
    end
  end
end
