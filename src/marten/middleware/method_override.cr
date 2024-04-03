module Marten
  abstract class Middleware
    # Middleware to convert POST requests containing a "_method" field with the value "DELETE" into DELETE requests.
    class MethodOverride < Middleware
      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        # Check if it's the method is allowed request and the override param key is present in the request body
        if allowed?(request)
          if method = extract_override_method(request)
            if allowed_override_method?(method)
              request.method = method
            end
          end
        end

        get_response.call
      end

      def allowed?(request)
        request.post?
      end

      def allowed_override_method?(method)
        Marten::HTTP::Request::Method.valid?(method)
      end

      def extract_override_method(request)
        value = request.data[override_param_key]? if (request.urlencoded? || request.form_data?)

        return Marten::HTTP::Request::Method.parse?(value) if value.is_a?(String)

        nil
      end

      def override_param_key
        "_method"
      end
    end
  end
end
