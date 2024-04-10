module Marten
  module Conf
    class GlobalSettings
      # Allows to configure settings related to the method override middleware.
      class MethodOverride
        @allowed_methods : Array(String) = ["DELETE", "PATCH", "PUT"]
        @http_header_name : String = "X-Http-Method-Override"
        @input_name : String = "_method"

        # Returns an array containing the HTTP methods allowed for override.
        getter allowed_methods

        # Returns the name of the HTTP header used to signal method overrides (e.g., in forms).
        getter http_header_name

        # Returns the name of the input field used to signal method overrides (e.g., in forms).
        getter input_name

        # Sets the name of the HTTP header used for method overrides.
        setter http_header_name

        # Sets the name of the input field used for method overrides.
        setter input_name

        # Sets the array of HTTP methods that are allowed for override.
        def allowed_methods=(methods)
          @allowed_methods = methods.map do |method|
            upcase_method = method.upcase

            unless Marten::HTTP::Constants::METHODS.includes?(upcase_method)
              raise Errors::InvalidConfiguration.new("Invalid HTTP method '#{method}'")
            end

            upcase_method
          end
        end
      end
    end
  end
end
