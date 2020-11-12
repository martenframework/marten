module Marten
  module Server
    INSTANCE = ::HTTP::Server.new(
      [
        ::HTTP::ErrorHandler.new,
        Handlers::Logger.new,
        Handlers::Error.new,
        Handlers::Middleware.new,
        Handlers::Routing.new,
      ]
    )

    def self.setup
      INSTANCE.bind_tcp(Marten.settings.host, Marten.settings.port, Marten.settings.port_reuse)
      # TODO: add support for TLS.
    end

    def self.addresses
      # TODO: add support for TLS.
      INSTANCE.addresses.map { |address| "http://#{address}" }
    end

    def self.start
      INSTANCE.listen
    end

    def self.stop
      INSTANCE.close
    end
  end
end
