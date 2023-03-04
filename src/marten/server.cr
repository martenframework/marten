module Marten
  # Wrapper around the Marten server.
  module Server
    # Returns the addresses on which the server is listening.
    def self.addresses : Array(String)
      instance.addresses.map { |address| "http://#{address}" }
    end

    # Returns the global HTTP server instance.
    def self.instance : ::HTTP::Server
      @@instance ||= ::HTTP::Server.new(
        [
          ::HTTP::ErrorHandler.new,
          Handlers::Logger.new,
          Handlers::Error.new,
          Handlers::HostVerification.new,
          Handlers::Middleware.new,
          Handlers::Routing.new,
        ]
      )
    end

    # Setups the server (TCP binding).
    def self.setup : Nil
      instance.bind_tcp(Marten.settings.host, Marten.settings.port, Marten.settings.port_reuse)
    end

    # Starts the server.
    def self.start : Nil
      instance.listen
    end

    # Stops the server.
    def self.stop : Nil
      instance.close
    end
  end
end
