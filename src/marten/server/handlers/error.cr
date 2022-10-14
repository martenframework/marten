require "./concerns/handler_response_converter"

module Marten
  module Server
    module Handlers
      class Error
        include ::HTTP::Handler
        include HandlerResponseConverter

        def call(context : ::HTTP::Server::Context)
          call_next(context)
        rescue error : Marten::HTTP::Errors::NotFound | Marten::Routing::Errors::NoResolveMatch
          if Marten.settings.debug
            handler = Marten::Handlers::Defaults::Debug::PageNotFound.new(context.marten.request)
            handler.error = error
          else
            handler = Marten.settings.handler404.new(context.marten.request)
          end

          convert_handler_response(context, handler.dispatch.as(HTTP::Response))
        rescue Marten::HTTP::Errors::SuspiciousOperation
          handler = Marten.settings.handler400.new(context.marten.request)
          convert_handler_response(context, handler.dispatch.as(HTTP::Response))
        rescue Marten::HTTP::Errors::PermissionDenied
          handler = Marten.settings.handler403.new(context.marten.request)
          convert_handler_response(context, handler.dispatch.as(HTTP::Response))
        rescue e : Exception
          Log.error { "Internal Server Error: #{context.request.path}\n#{e.inspect_with_backtrace}" }

          if Marten.settings.debug
            handler = Marten::Handlers::Defaults::Debug::ServerError.new(context.marten.request)
            handler.bind_error(e)
          else
            handler = Marten.settings.handler500.new(context.marten.request)
          end

          convert_handler_response(context, handler.dispatch.as(HTTP::Response))
        end
      end
    end
  end
end
