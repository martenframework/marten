module Marten
  module Server
    # Provides a WebSocket-based live reload server for development.
    # This server is only enabled in development mode when the live_reload setting is enabled.
    module LiveReload
      @@clients = [] of ::HTTP::WebSocket
      @@server : ::HTTP::Server?
      @@watcher : FileWatcher?

      # List of file patterns to watch for changes
      DEFAULT_WATCH_PATTERNS = [
        "src/**/*.cr",
        "src/**/*.ecr",
        "src/assets/**/*",
        "config/**/*",
      ]

      # Default options for the live reload server
      DEFAULT_OPTIONS = {
        port: 35729,
        host: "localhost",
        patterns: DEFAULT_WATCH_PATTERNS,
        debounce: 1.second,
      }

      # Returns whether the live reload server is running
      def self.running? : Bool
        !@@server.nil?
      end

      # Returns all connected WebSocket clients
      def self.clients : Array(::HTTP::WebSocket)
        @@clients
      end

      # Start the live reload server with the given options
      def self.start(options = DEFAULT_OPTIONS) : Nil
        return if running?

        spawn do
          setup_server(options)
          setup_watcher(options)
        end
      end

      # Stop the live reload server if it's running
      def self.stop : Nil
        if server = @@server
          server.close
          @@server = nil
        end

        if watcher = @@watcher
          watcher.stop
          @@watcher = nil
        end

        @@clients.clear
      end

      # Trigger a reload on all connected clients
      def self.trigger_reload : Nil
        clients.each do |client|
          begin
            client.send("reload")
          rescue
            @@clients.delete(client)
          end
        end
      end

      private def self.setup_server(options)
        server = ::HTTP::Server.new do |context|
          if context.request.resource == "/live_reload"
            ws_handler = ::HTTP::WebSocketHandler.new do |ws, _ctx|
              @@clients << ws

              # Keep connection alive with ping/pong
              spawn do
                loop do
                  begin
                    ws.ping
                    sleep 30
                  rescue
                    break
                  end
                end
              end

              # Handle disconnection
              ws.on_close do
                @@clients.delete(ws)
              end
            end

            ws_handler.call(context)
          end
        end

        server.bind_tcp options[:host], options[:port]
        server.listen

        @@server = server
      end

      private def self.setup_watcher(options)
        watcher = FileWatcher.new(
          patterns: options[:patterns],
          debounce: options[:debounce]
        )

        watcher.on_change do
          trigger_reload
        end

        watcher.start
        @@watcher = watcher
      end
    end
  end
end
