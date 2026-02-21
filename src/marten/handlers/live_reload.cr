module Marten
  module Handlers
    # Handler that provides Server-Sent Events (SSE) for live reload functionality.
    # This handler is automatically mounted when live reload is enabled in development mode.
    class LiveReload < Base
      @@channels = [] of Channel(String)

      def get
        channel = Channel(String).new
        @@channels << channel

        streamed_content = Iterator.of do
          begin
            message = channel.receive
            "data: #{message}\n\n"
          rescue Channel::ClosedError
            cleanup(channel)
            Iterator::Stop::INSTANCE
          end
        end

        respond(
          streamed_content,
          content_type: "text/event-stream",
          status: 200
        ).tap do |response|
          response.headers["Cache-Control"] = "no-cache"
          response.headers["Connection"] = "keep-alive"
        end
      end

      def self.broadcast(message : String)
        @@channels.reject! do |channel|
          begin
            channel.send(message)
            false
          rescue Channel::ClosedError
            true
          end
        end
      end

      private def cleanup(channel)
        @@channels.delete(channel)
      end
    end
  end
end
