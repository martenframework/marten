module Marten
  module Server
    module Handlers
      class DebugLogger
        include ::HTTP::Handler
        include Core::DebugModeLoggable

        def call(context : ::HTTP::Server::Context)
          marten_request = context.marten.request

          Log.info { "\nStarted \"#{marten_request.method} #{marten_request.path}\" at #{Time.utc}..." }

          if !marten_request.data.empty?
            debug_mode_info_log("  ▸ Data: #{marten_request.data.to_h}")
          end

          if !marten_request.query_params.empty?
            debug_mode_info_log("  ▸ Query params: #{marten_request.query_params.to_h}")
          end

          duration = Time.measure { Log.with_context(prefix: "  ▸ ") { call_next(context) } }

          # Note: we retrieve the status code from the server's response directly because we won't necessarily have a
          # Marten response object at hand here (eg. this can be the case when errors happen or pages are not found).
          Log.info { "Completed with \"#{context.response.status_code}\" in #{duration.total_milliseconds}ms" }
        end
      end
    end
  end
end
