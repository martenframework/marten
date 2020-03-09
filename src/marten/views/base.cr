module Marten
  module Views
    class Base
      HTTP_METHOD_NAMES = %w(get post put patch delete head options trace)

      @@http_method_names : Array(String)?

      def self.http_method_names(*method_names : String | Symbol)
        @@http_method_names = method_names.to_a.map(&.to_s)
      end

      def self.http_method_names : Array(String)
        @@http_method_names || HTTP_METHOD_NAMES
      end

      def dispatch(request : HTTP::Request, *args, **kwargs)
        if self.class.http_method_names.includes?(request.method.downcase)
          call_http_method(request, *args, **kwargs)
        else
          handle_http_method_not_allowed
        end
      end

      def get(request, *args, **kwargs)
        handle_http_method_not_allowed
      end

      def post(request, *args, **kwargs)
        handle_http_method_not_allowed
      end

      def put(request, *args, **kwargs)
        handle_http_method_not_allowed
      end

      def patch(request, *args, **kwargs)
        handle_http_method_not_allowed
      end

      def delete(request, *args, **kwargs)
        handle_http_method_not_allowed
      end

      def trace(request, *args, **kwargs)
        handle_http_method_not_allowed
      end

      def head(request, *args, **kwargs)
        # By default HEAD requests are delegated to the get handler - which will result in a not
        # allowed response if the latest is not defined.
        get(request, *args, **kwargs)
      end

      def options(request, *args, **kwargs)
        # Responds to requests for the OPTIONS HTTP verb.
        response = HTTP::Response.new
        response["Allow"] = self.class.http_method_names.map(&.upcase).join(", ")
        response["Content-Length"] = "0"
        response
      end

      private def handle_http_method_not_allowed
        HTTP::Response::NotAllowed.new(self.class.http_method_names)
      end

      private def call_http_method(request, *args, **kwargs)
        case request.method.downcase
        when "get"
          get(request, *args, **kwargs)
        when "post"
          post(request, *args, **kwargs)
        when "put"
          put(request, *args, **kwargs)
        when "patch"
          patch(request, *args, **kwargs)
        when "delete"
          delete(request, *args, **kwargs)
        when "head"
          head(request, *args, **kwargs)
        when "options"
          options(request, *args, **kwargs)
        when "trace"
          trace(request, *args, **kwargs)
        end
      end
    end
  end
end
