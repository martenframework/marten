require "./concerns/callbacks"
require "./concerns/request_forgery_protection"

module Marten
  module Views
    # Base view implementation.
    #
    # This class defines the behaviour of a view. A view is initialized from an HTTP request and it is responsible for
    # processing a request in order to produce an HTTP response (which can be an HTML content, a redirection, etc).
    class Base
      include Callbacks
      include RequestForgeryProtection

      HTTP_METHOD_NAMES = %w(get post put patch delete head options trace)

      @@http_method_names : Array(String) = HTTP_METHOD_NAMES

      @response : HTTP::Response? = nil

      # Returns the HTTP method names that are allowed for the view.
      class_getter http_method_names

      # Returns the associated HTTP request.
      getter request

      # Returns the HTTP response.
      #
      # This method will return the `Marten::HTTP::Response` object that is returned by the `#dispatch` method, so that
      # it can be used in the context of `#after_dispatch` callbacks.
      getter response

      # Returns the associated route parameters.
      getter params

      # Allows to specify the allowed HTTP methods.
      def self.http_method_names(*method_names : String | Symbol)
        @@http_method_names = method_names.to_a.map(&.to_s)
      end

      def initialize(@request : HTTP::Request, @params : Hash(String, Routing::Parameter::Types))
      end

      def initialize(@request : HTTP::Request)
        @params = {} of String => Routing::Parameter::Types
      end

      # Triggers the execution of the view in order to produce an HTTP response.
      #
      # This method will be called by the Marten server when it comes to produce an HTTP response once a view has been
      # identified for the considered route. This method will execute the view method associated with the considered
      # HTTP method (eg. `#get` for the `GET` method) in order to return the final HTTP response. A 405 response will be
      # returned if the considered HTTP method is not allowed. The `#dispatch` method can also be overridden on a
      # per-view basis in order to implement any other arbitrary logics if necessary.
      def dispatch : Marten::HTTP::Response
        if self.class.http_method_names.includes?(request.method.downcase)
          call_http_method
        else
          handle_http_method_not_allowed
        end
      end

      # Handles a `GET` HTTP request and returns a `Marten::HTTP::Response` object.
      #
      # The default implementation will return a 405 (not allowed) response.
      def get
        handle_http_method_not_allowed
      end

      # Handles a `POST` HTTP request and returns a `Marten::HTTP::Response` object.
      #
      # The default implementation will return a 405 (not allowed) response.
      def post
        handle_http_method_not_allowed
      end

      # Handles a `PUT` HTTP request and returns a `Marten::HTTP::Response` object.
      #
      # The default implementation will return a 405 (not allowed) response.
      def put
        handle_http_method_not_allowed
      end

      # Handles a `PATCH` HTTP request and returns a `Marten::HTTP::Response` object.
      #
      # The default implementation will return a 405 (not allowed) response.
      def patch
        handle_http_method_not_allowed
      end

      # Handles a `DELETE` HTTP request and returns a `Marten::HTTP::Response` object.
      #
      # The default implementation will return a 405 (not allowed) response.
      def delete
        handle_http_method_not_allowed
      end

      # Handles a `TRACE` HTTP request and returns a `Marten::HTTP::Response` object.
      #
      # The default implementation will return a 405 (not allowed) response.
      def trace
        handle_http_method_not_allowed
      end

      # Handles a `HEAD` HTTP request and returns a `Marten::HTTP::Response` object.
      #
      # The default implementation is to return whatever is returned by the `#get` method.
      def head
        # By default HEAD requests are delegated to the get handler - which will result in a not allowed response if the
        # latest is not defined.
        get
      end

      # Returns an empty response associated with a given status code.
      def head(status : Int32) : HTTP::Response
        HTTP::Response.new(content: "", content_type: "", status: status)
      end

      # Handles an `OPTIONS` HTTP request and returns a `Marten::HTTP::Response` object.
      #
      # The default implementation will return an HTTP response that includes an `Allow` header populated from the
      # configured allowed HTTP methods.
      def options
        # Responds to requests for the OPTIONS HTTP verb.
        response = HTTP::Response.new
        response["Allow"] = self.class.http_method_names.join(", ") { |m| m.upcase }
        response["Content-Length"] = "0"
        response
      end

      # :nodoc:
      def process_dispatch : Marten::HTTP::Response
        before_callbacks_response = run_before_dispatch_callbacks

        @response = before_callbacks_response || dispatch

        after_callbacks_response = run_after_dispatch_callbacks
        after_callbacks_response || response!
      end

      # Returns an HTTP response generated from a content string, content type and status code.
      def respond(content = "", content_type = HTTP::Response::DEFAULT_CONTENT_TYPE, status = 200)
        HTTP::Response.new(content: content, content_type: content_type, status: status)
      end

      # Same as `#response` but with a nil-safety check.
      def response!
        response.not_nil!
      end

      # Convenient helper method to resolve a route name.
      delegate reverse, to: Marten.routes

      private def handle_http_method_not_allowed
        HTTP::Response::NotAllowed.new(self.class.http_method_names)
      end

      private def call_http_method
        case request.method.downcase
        when "get"
          get
        when "post"
          post
        when "put"
          put
        when "patch"
          patch
        when "delete"
          delete
        when "head"
          head
        when "options"
          options
        when "trace"
          trace
        else
          handle_http_method_not_allowed
        end
      end
    end
  end
end
