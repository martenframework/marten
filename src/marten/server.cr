module Marten
  # Wrapper around the Marten server.
  module Server
    # Returns the addresses on which the server is listening.
    def self.addresses : Array(String)
      instance.addresses.map { |address| "http://#{address}" }
    end

    # Returns the handlers of the server.
    def self.handlers
      [
        ::HTTP::ErrorHandler.new,
        Marten.settings.debug? ? Handlers::DebugLogger.new : Handlers::Logger.new,
        Handlers::Error.new,
        Handlers::Middleware.new,
        Handlers::Routing.new,
      ]
    end

    # Returns the global HTTP server instance.
    def self.instance : ::HTTP::Server
      @@instance ||= ::HTTP::Server.new(handlers)
    end

    # Setups the server (TCP binding).
    def self.setup : Nil
      instance.bind_tcp(Marten.settings.host, Marten.settings.port, Marten.settings.port_reuse)

      # Start live reload if enabled in development mode
      if Marten.settings.debug? && Marten.settings.live_reload_enabled?
        LiveReload.start(Marten.settings.live_reload_patterns)
      end
    end

    # Starts the server.
    def self.start : Nil
      instance.listen
    end

    # Stops the server.
    def self.stop : Nil
      instance.close
      LiveReload.stop if LiveReload.running?
    end
  end
end
