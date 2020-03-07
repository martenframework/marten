module Marten
  module Server
    class Context
      @request : Marten::HTTP::Request?

      def initialize(@context : ::HTTP::Server::Context)
      end

      def request
        @request ||= Marten::HTTP::Request.new(@context.request)
      end
    end
  end
end

class HTTP::Server::Context
  def marten
    @marten ||= Marten::Server::Context.new(self)
  end
end
