module Marten
  module Server
    module Handlers
      class Routing
        include ::HTTP::Handler
        include HandlerResponseConverter
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
          matched = context.marten.request.route?

          if matched.nil?
            if !Marten.settings.trailing_slash.do_nothing?
              if should_redirect_with_slash?(context)
                context.marten.response = HTTP::Response::MovedPermanently.new(location_with_slash(context))
                return context
              elsif should_redirect_without_slash?(context)
                context.marten.response = HTTP::Response::MovedPermanently.new(location_without_slash(context))
                return context
              end
            end

            return process_not_found_error(context)
          end

          debug_mode_info_log("Routed to: #{matched.handler.name}")

          handler = matched.handler.new(context.marten.request, matched.kwargs)
          context.marten.response = handler.process_dispatch.as(HTTP::Response)

          context
        rescue ex : Marten::Routing::Errors::NoResolveMatch
          if !Marten.settings.trailing_slash.do_nothing?
            if should_redirect_with_slash?(context)
              context.marten.response = HTTP::Response::MovedPermanently.new(location_with_slash(context))
              return context
            elsif should_redirect_without_slash?(context)
              context.marten.response = HTTP::Response::MovedPermanently.new(location_without_slash(context))
              return context
            end
          end

          process_not_found_error(context, ex)
        rescue ex : Marten::HTTP::Errors::NotFound | Marten::Routing::Errors::NoResolveMatch
          process_not_found_error(context, ex)
        rescue ex : Marten::HTTP::Errors::SuspiciousOperation
          process_suspicious_operation_error(context, ex)
        rescue Marten::HTTP::Errors::PermissionDenied
          handler = Marten.settings.handler403.new(context.marten.request)
          convert_handler_response(context, handler.dispatch.as(HTTP::Response))
        end

        private def should_redirect_with_slash?(context)
          Marten.settings.trailing_slash.add? && !context.request.path.ends_with?(SLASH_CHAR)
        end

        private def should_redirect_without_slash?(context)
          Marten.settings.trailing_slash.remove? && context.request.path.ends_with?(SLASH_CHAR) &&
            context.request.path != SLASH_STRING
        end

        private def process_not_found_error(context, error = nil)
          if Marten.settings.debug
            handler = Marten::Handlers::Defaults::Debug::PageNotFound.new(context.marten.request)
            handler.error = error if error
          else
            handler = Marten.settings.handler404.new(context.marten.request)
          end

          context.marten.response = handler.process_dispatch.as(HTTP::Response)
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
