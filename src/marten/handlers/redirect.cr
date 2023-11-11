module Marten
  module Handlers
    # Handler allowing to conveniently return redirect responses.
    class Redirect < Base
      # Returns the configured route name that should be resolved to produce the URL to redirect to.
      #
      # Defaults to `nil`.
      class_getter route_name : String?

      # Returns the configured raw URL to redirect to.
      #
      # Defaults to `nil`.
      class_getter url : String?

      # Indicates whether query strings should be copied into the redirect URL or not.
      #
      # Defaults to `false`.
      class_getter? forward_query_string : Bool = false

      # Indicates whether the redirection is permanent or not.
      #
      # Defaults to `false`.
      class_getter? permanent : Bool = false

      # Allows to configure whether query strings should be copied into the redirect URL.
      def self.forward_query_string(forward_query_string : Bool)
        @@forward_query_string = forward_query_string
      end

      # Allows to configure whether the redirection is permanent or not.
      def self.permanent(permanent : Bool)
        @@permanent = permanent
      end

      # Allows to configure the route name that should be resolved to produce the URL to redirect to.
      def self.route_name(route_name : String?)
        @@route_name = route_name
      end

      # Allows to configure a raw URL to redirect to.
      def self.url(url : String?)
        @@url = url
      end

      def get
        url = redirect_url
        return HTTP::Response::Gone.new if url.nil?
        redirect(url, permanent: self.class.permanent?)
      end

      def head
        get
      end

      def post
        get
      end

      def options
        get
      end

      def delete
        get
      end

      def put
        get
      end

      def patch
        get
      end

      # Returns the URL to redirect to.
      #
      # By default, the URL will be determined from the configured `#url` and `#route_name` values. This method can be
      # overridden on subclasses in order to define any arbitrary logics that might be necessary in order to determine
      # the final redirection URL.
      def redirect_url
        url = self.class.url || (self.class.route_name && reverse(self.class.route_name.not_nil!, params))
        url = "#{url}?#{request.query_params.as_query}" if self.class.forward_query_string?
        url
      end
    end
  end
end
