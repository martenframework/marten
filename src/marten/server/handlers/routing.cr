module Marten
  module Server
    module Handlers
      class Routing
        include ::HTTP::Handler
        include Core::DebugModeLoggable

        def call(context : ::HTTP::Server::Context)
          process(context)
        end

        private SLASH_CHAR   = '/'
        private SLASH_STRING = "/"

        private def location_with_slash(context)
          "#{context.marten.request.scheme}://#{context.marten.request.host}#{context.marten.request.path}/"
        end

        private def location_without_slash(context)
          "#{context.marten.request.scheme}://#{context.marten.request.host}#{context.marten.request.path[0..-2]}"
        end

        private def process(context)
          matched = Marten.routes.resolve(context.request.path)

          debug_mode_info_log("Routed to: #{matched.handler.name}")

          handler = matched.handler.new(context.marten.request, matched.kwargs)
          context.marten.response = handler.process_dispatch.as(HTTP::Response)

          context
        rescue error : Marten::Routing::Errors::NoResolveMatch
          raise error if Marten.settings.trailing_slash.do_nothing?

          if should_redirect_with_slash?(context)
            context.marten.response = HTTP::Response::MovedPermanently.new(location_with_slash(context))
            return context
          elsif should_redirect_without_slash?(context)
            context.marten.response = HTTP::Response::MovedPermanently.new(location_without_slash(context))
            return context
          end

          raise error
        end

        private def should_redirect_with_slash?(context)
          Marten.settings.trailing_slash.add? && !context.request.path.ends_with?(SLASH_CHAR)
        end

        private def should_redirect_without_slash?(context)
          Marten.settings.trailing_slash.remove? && context.request.path.ends_with?(SLASH_CHAR) &&
            context.request.path != SLASH_STRING
        end
      end
    end
  end
end
