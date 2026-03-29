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

    # Setups the server (TCP or Unix socket binding).
    def self.setup : Nil
      if socket = Marten.settings.socket
        instance.bind_unix(socket)
      else
        instance.bind_tcp(Marten.settings.host, Marten.settings.port, Marten.settings.port_reuse)
      end
    end

    # Starts the server.
    def self.start : Nil
      instance.listen
    end

    # Stops the server.
    def self.stop : Nil
      instance.close
    end

    # :nodoc:
    def self.reset_instance : Nil
      @@instance = nil
    end
  end
end
