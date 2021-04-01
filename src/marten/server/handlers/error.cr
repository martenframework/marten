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
          view_klass = Marten.settings.debug ? Marten::Views::Defaults::Debug::PageNotFound : Marten.settings.view404
          view = view_klass.new(context.marten.request)
          convert_view_response(context, view.dispatch.as(HTTP::Response))
        rescue Marten::HTTP::Errors::SuspiciousOperation
          view = Marten.settings.view400.new(context.marten.request)
          convert_view_response(context, view.dispatch.as(HTTP::Response))
        rescue e : Exception
          Log.error { "Internal Server Error: #{context.request.path}\n#{e.inspect_with_backtrace}" }
          view = Marten.settings.view500.new(context.marten.request)
          convert_view_response(context, view.dispatch.as(HTTP::Response))
        end
      end
    end
  end
end
