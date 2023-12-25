require "./concerns/callbacks"
require "./concerns/content_security_policy"
require "./concerns/cookies"
require "./concerns/flash"
require "./concerns/request_forgery_protection"
require "./concerns/session"
require "./concerns/x_frame_options"

module Marten
  module Handlers
    # Base handler implementation.
    #
    # This class defines the behaviour of a handler. A handler is initialized from an HTTP request and it is responsible
    # for processing a request in order to produce an HTTP response (which can be an HTML content, a redirection, etc).
    class Base
      include Callbacks
      include Cookies
      include Flash
      include RequestForgeryProtection
      include Session
      include ContentSecurityPolicy
      include XFrameOptions

      HTTP_METHOD_NAMES = %w(get post put patch delete head options trace)

      @@http_method_names : Array(String) = HTTP_METHOD_NAMES

      @context : Marten::Template::Context? = nil
      @response : HTTP::Response? = nil

      # Returns the HTTP method names that are allowed for the handler.
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

      def initialize(@request : HTTP::Request, @params : Routing::MatchParameters)
      end

      def initialize(@request : HTTP::Request, **kwargs)
        @params = Routing::MatchParameters.new
        kwargs.each { |key, value| @params[key.to_s] = value }
      end

      # Returns the global template context.
      #
      # This context object can be mutated for the lifetime of the handler in order to define which variables will be
      # made available to the template runtime.
      def context
        @context ||= Marten::Template::Context.from(nil, request)
      end

      # Triggers the execution of the handler in order to produce an HTTP response.
      #
      # This method will be called by the Marten server when it comes to produce an HTTP response once a handler has
      # been identified for the considered route. This method will execute the handler method associated with the
      # considered HTTP method (eg. `#get` for the `GET` method) in order to return the final HTTP response. A 405
      # response will be returned if the considered HTTP method is not allowed. The `#dispatch` method can also be
      # overridden on a per-handler basis in order to implement any other arbitrary logics if necessary.
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
      def head(status : ::HTTP::Status | Int32) : HTTP::Response
        HTTP::Response.new(
          content: "",
          content_type: "",
          status: ::HTTP::Status.new(status).to_i
        )
      end

      # Returns an HTTP response containing the passed raw JSON string.
      #
      # The response will use the `application/json` content type and the `200` status code (the latest can be set to
      # something else through the use of the `status` argument).
      def json(raw_json : String, status : ::HTTP::Status | Int32 = 200)
        HTTP::Response.new(
          content: raw_json,
          content_type: "application/json",
          status: ::HTTP::Status.new(status).to_i
        )
      end

      # Returns an HTTP response containing the passed object serialized as JSON.
      #
      # The response will use the `application/json` content type and the `200` status code (the latest can be set to
      # something else through the use of the `status` argument).
      def json(serializable, status : ::HTTP::Status | Int32 = 200)
        HTTP::Response.new(
          content: serializable.to_json,
          content_type: "application/json",
          status: ::HTTP::Status.new(status).to_i
        )
      end

      # Handles an `OPTIONS` HTTP request and returns a `Marten::HTTP::Response` object.
      #
      # The default implementation will return an HTTP response that includes an `Allow` header populated from the
      # configured allowed HTTP methods.
      def options
        # Responds to requests for the OPTIONS HTTP verb.
        response = HTTP::Response.new
        response["Allow"] = self.class.http_method_names.join(", ", &.upcase)
        response["Content-Length"] = "0"
        response
      end

      # :nodoc:
      def process_dispatch : Marten::HTTP::Response
        before_dispatch_response = run_before_dispatch_callbacks

        @response = before_dispatch_response.nil? ? dispatch : before_dispatch_response

        after_dispatch_response = run_after_dispatch_callbacks
        @response = after_dispatch_response if !after_dispatch_response.nil?

        response!
      end

      # Returns a redirect HTTP response for a specific `url`.
      #
      # By default, the HTTP response returned will be a "302 Found", unless the `permanent` argument is set to `true`
      # (in which case the response will be a "301 Moved Permanently").
      def redirect(url : String, permanent = false)
        permanent ? HTTP::Response::MovedPermanently.new(url) : HTTP::Response::Found.new(url)
      end

      # Returns an HTTP response whose content is generated by rendering a specific template.
      #
      # The context of the rendered template can be specified using the `context` argument, while the content type and
      # status code of the response can be specified using the `content_type` and `status` arguments.
      def render(
        template_name : String,
        context : Hash | NamedTuple | Nil | Marten::Template::Context = nil,
        content_type = HTTP::Response::DEFAULT_CONTENT_TYPE,
        status : ::HTTP::Status | Int32 = 200
      )
        self.context.merge(context) unless context.nil?
        self.context["handler"] = self

        before_render_response = run_before_render_callbacks

        if before_render_response.is_a?(HTTP::Response)
          before_render_response
        else
          HTTP::Response.new(
            content: Marten.templates.get_template(template_name).render(self.context),
            content_type: content_type,
            status: ::HTTP::Status.new(status).to_i
          )
        end
      end

      # Returns an HTTP response generated from a content string, content type and status code.
      def respond(
        content = "",
        content_type = HTTP::Response::DEFAULT_CONTENT_TYPE,
        status : ::HTTP::Status | Int32 = 200
      )
        HTTP::Response.new(
          content: content,
          content_type: content_type,
          status: ::HTTP::Status.new(status).to_i
        )
      end

      # Returns a streamed HTTP response generated from an iterator of strings, content type and status code.
      def respond(
        streamed_content : Iterator(String),
        content_type = HTTP::Response::DEFAULT_CONTENT_TYPE,
        status : ::HTTP::Status | Int32 = 200
      )
        HTTP::Response::Streaming.new(
          streamed_content: streamed_content,
          content_type: content_type,
          status: ::HTTP::Status.new(status).to_i
        )
      end

      # Same as `#response` but with a nil-safety check.
      def response!
        response.not_nil!
      end

      # Convenient helper method to resolve a route name.
      delegate reverse, to: Marten.routes

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

      private def handle_http_method_not_allowed
        HTTP::Response::MethodNotAllowed.new(self.class.http_method_names)
      end
    end
  end
end
