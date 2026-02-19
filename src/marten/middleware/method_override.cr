module Marten
  abstract class Middleware
    # Overrides the HTTP method of a request.
    #
    # This middleware overrides the HTTP method of a incoming request that include a `_method` field
    # (in form data or URL-encoded data) or a `X-Http-Method-Override` header,
    # enabling the use of HTTP methods beyond `GET` and `POST` in HTML forms.
    #
    # For example a `POST` request with `_method=DELETE` in its body would be treated as a DELETE request.
    class MethodOverride < Middleware
      @allowed_method_sets : Set(String)?

      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        if allowed?(request)
          if method = extract_override_method(request)
            request.method = method if allowed_override_method?(method)
          end
        end

        get_response.call
      end

      private def allowed?(request)
        request.post?
      end

      private def allowed_override_method?(method)
        allowed_method_sets.includes?(method.upcase)
      end

      private def allowed_method_sets
        @allowed_method_sets ||= Marten.settings.method_override.allowed_methods.to_set
      end

      private def extract_override_method(request)
        value = request.data[override_param_key]? if request.urlencoded? || request.form_data?

        return value if value.is_a?(String)

        request.headers[Marten.settings.method_override.http_header_name]?
      end

      private def override_param_key
        Marten.settings.method_override.input_name
      end
    end
  end
end
