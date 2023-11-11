require "./concerns/handler_response_converter"

module Marten
  module Server
    module Handlers
      class Error
        include ::HTTP::Handler
        include HandlerResponseConverter

        def call(context : ::HTTP::Server::Context)
          call_next(context)
        rescue ex : Marten::HTTP::Errors::NotFound | Marten::Routing::Errors::NoResolveMatch
          process_not_found_error(context, ex)
        rescue ex : Marten::HTTP::Errors::SuspiciousOperation
          process_suspicious_operation_error(context, ex)
        rescue Marten::HTTP::Errors::PermissionDenied
          handler = Marten.settings.handler403.new(context.marten.request)
          convert_handler_response(context, handler.dispatch.as(HTTP::Response))
        rescue ex : Exception
          process_server_error(context, ex)
        end

        private def process_not_found_error(context, error)
          if Marten.settings.debug
            handler = Marten::Handlers::Defaults::Debug::PageNotFound.new(context.marten.request)
            handler.error = error
          else
            handler = Marten.settings.handler404.new(context.marten.request)
          end

          convert_handler_response(context, handler.dispatch.as(HTTP::Response))
        end

        private def process_server_error(context, error)
          Log.error { "Internal Server Error: #{context.request.path}\n#{error.inspect_with_backtrace}" }

          if Marten.settings.debug
            handler = Marten::Handlers::Defaults::Debug::ServerError.new(context.marten.request)
            handler.bind_error(error)
          else
            handler = Marten.settings.handler500.new(context.marten.request)
          end

          convert_handler_response(context, handler.dispatch.as(HTTP::Response))
        end

        private def process_suspicious_operation_error(context, error)
          if Marten.settings.debug
            handler = Marten::Handlers::Defaults::Debug::ServerError.new(context.marten.request)
            handler.status = 400
            handler.bind_error(error)
          else
            handler = Marten.settings.handler400.new(context.marten.request)
          end

          convert_handler_response(context, handler.dispatch.as(HTTP::Response))
        end
      end
    end
  end
end
