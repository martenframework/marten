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
      server.bind_tcp("0.0.0.0", 8000)
      server.listen
    end
  end
end
