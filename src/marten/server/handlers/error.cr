module Marten
  module Server
    module Handlers
      class Error
        include ::HTTP::Handler

        def call(context : ::HTTP::Server::Context)
          call_next(context)
        rescue Marten::Routing::Errors::NoResolveMatch
          context.response.status_code = 404
          context.response.print("The requested resource was not found.")
        rescue e : Exception
          Marten.logger.error("Internal Server Error: #{context.request.path}\n#{e.inspect_with_backtrace}")
          context.response.status_code = 500
        end
      end
    end
  end
end
