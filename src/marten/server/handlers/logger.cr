module Marten
  module Server
    module Handlers
      class Logger
        include ::HTTP::Handler

        def call(context : ::HTTP::Server::Context)
          duration = Time.measure { call_next(context) }
          Log.info {
            "\"#{context.request.method} #{context.request.path}\" " \
            "#{context.response.status_code} - #{duration.total_milliseconds}ms"
          }
        end
      end
    end
  end
end
