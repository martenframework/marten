module Marten
  # Wrapper around the Marten server.
  module Server
    # Returns the addresses on which the server is listening.
    def self.addresses
      INSTANCE.addresses.map { |address| "http://#{address}" }
    end

    # Setups the server (TCP binding).
    def self.setup
      INSTANCE.bind_tcp(Marten.settings.host, Marten.settings.port, Marten.settings.port_reuse)
    end

    # Starts the server.
    def self.start
      INSTANCE.listen
    end

    # Stops the server.
    def self.stop
      INSTANCE.close
    end

    private INSTANCE = ::HTTP::Server.new(
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
end
