module Marten
  module Server
    def self.run
      server = ::HTTP::Server.new(
        [
          ::HTTP::ErrorHandler.new,
          Handlers::Logger.new,
          Handlers::Error.new,
          Handlers::Routing.new,
          Handlers::Response.new,
        ]
      )

      server.bind_tcp(Marten.settings.host, Marten.settings.port, Marten.settings.port_reuse)
      # TODO: add support for TLS.

      server.listen
    end
  end
end
