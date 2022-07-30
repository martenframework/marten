require "./concerns/view_response_converter"

module Marten
  module Server
    module Handlers
      class Error
        include ::HTTP::Handler
        include ViewResponseConverter

        def call(context : ::HTTP::Server::Context)
          call_next(context)
        rescue error : Marten::HTTP::Errors::NotFound | Marten::Routing::Errors::NoResolveMatch
          if Marten.settings.debug
            view = Marten::Views::Defaults::Debug::PageNotFound.new(context.marten.request)
            view.error = error
          else
            view = Marten.settings.view404.new(context.marten.request)
          end

          convert_view_response(context, view.dispatch.as(HTTP::Response))
        rescue Marten::HTTP::Errors::SuspiciousOperation
          view = Marten.settings.view400.new(context.marten.request)
          convert_view_response(context, view.dispatch.as(HTTP::Response))
        rescue Marten::HTTP::Errors::PermissionDenied
          view = Marten.settings.view403.new(context.marten.request)
          convert_view_response(context, view.dispatch.as(HTTP::Response))
        rescue e : Exception
          Log.error { "Internal Server Error: #{context.request.path}\n#{e.inspect_with_backtrace}" }

          if Marten.settings.debug
            view = Marten::Views::Defaults::Debug::ServerError.new(context.marten.request)
            view.bind_error(e)
          else
            view = Marten.settings.view500.new(context.marten.request)
          end

          convert_view_response(context, view.dispatch.as(HTTP::Response))
        end
      end
    end
  end
end
