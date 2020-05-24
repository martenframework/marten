module Marten
  module Views
    class Base
      HTTP_METHOD_NAMES = %w(get post put patch delete head options trace)

      @@http_method_names : Array(String)?

      getter request
      getter params

      def self.http_method_names(*method_names : String | Symbol)
        @@http_method_names = method_names.to_a.map(&.to_s)
      end

      def self.http_method_names : Array(String)
        @@http_method_names || HTTP_METHOD_NAMES
      end

      def initialize(@request : HTTP::Request, @params : Hash(String, Routing::Parameter::Types))
      end

      def initialize(@request : HTTP::Request)
        @params = {} of String => Routing::Parameter::Types
      end

      def dispatch : Marten::HTTP::Response
        if self.class.http_method_names.includes?(request.method.downcase)
          call_http_method
        else
          handle_http_method_not_allowed
        end
      end

      def get
        handle_http_method_not_allowed
      end

      def post
        handle_http_method_not_allowed
      end

      def put
        handle_http_method_not_allowed
      end

      def patch
        handle_http_method_not_allowed
      end

      def delete
        handle_http_method_not_allowed
      end

      def trace
        handle_http_method_not_allowed
      end

      def head
        # By default HEAD requests are delegated to the get handler - which will result in a not allowed response if the
        # latest is not defined.
        get
      end

      def options
        # Responds to requests for the OPTIONS HTTP verb.
        response = HTTP::Response.new
        response["Allow"] = self.class.http_method_names.map(&.upcase).join(", ")
        response["Content-Length"] = "0"
        response
      end

      protected delegate reverse, to: Marten.routes

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
