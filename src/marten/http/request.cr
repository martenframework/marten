module Marten
  module HTTP
    # Represents an HTTP request processed by Marten.
    #
    # When a page is request, Marten creates a `Marten::HTTP::Request` that gives access to all the information and
    # metadata of the incoming request.
    class Request
      def initialize(@request : ::HTTP::Request)
      end

      # Returns the raw body of the request as a string.
      def body : String
        @body ||= @request.body.nil? ? "" : @request.body.as(IO).gets_to_end
      end

      # Returns the HTTP headers embedded in the request.
      def headers : ::HTTP::Headers
        @request.headers
      end

      # Returns a string representation of HTTP method that was used in the request.
      #
      # The returned method name (eg. "GET" or "POST") is completely uppercase.
      def method : String
        @request.method.upcase
      end

      # Returns the request path as a string.
      #
      # Only the path of the request is included (without scheme or domain).
      def path : String
        @request.path
      end

      def query_params
        QueryParams.new(@request.query_params)
      end
    end
  end
end
