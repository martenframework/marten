require "./concerns/view_response_converter"

module Marten
  module Server
    module Handlers
      class Error
        include ::HTTP::Handler
        include ViewResponseConverter

        def call(context : ::HTTP::Server::Context)
          call_next(context)
        rescue Marten::Routing::Errors::NoResolveMatch
          context.response.status_code = 404
          context.response.print("The requested resource was not found.")
        rescue e : Exception
          Marten.logger.error("Internal Server Error: #{context.request.path}\n#{e.inspect_with_backtrace}")
          view = Views::Defaults::ServerError.new(context.marten.request)
          convert_view_response(context, view.dispatch)
        end
      end
    end
  end
end
