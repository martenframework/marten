module Marten
  module Server
    # Marten's specific request/response context.
    class Context
      getter request
      getter response

      @request : HTTP::Request
      @response : HTTP::Response?

      def initialize(@context : ::HTTP::Server::Context)
        @request = Marten::HTTP::Request.new(@context.request)
      end

      def response=(response : HTTP::Response)
        @response = response
      end
    end
  end
end
