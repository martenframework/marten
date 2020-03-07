module Marten
  module HTTP
    class Request
      def initialize(@request : ::HTTP::Request)
      end

      def method
        @request.method
      end
    end
  end
end
