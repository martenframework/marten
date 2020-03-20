module Marten
  module HTTP
    class Request
      def initialize(@request : ::HTTP::Request)
      end

      def method
        @request.method
      end

      def path
        @request.path
      end
    end
  end
end
