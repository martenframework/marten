module Marten
  module Server
    module Handlers
      class Routing
        include ::HTTP::Handler

        def call(context : ::HTTP::Server::Context)
          process(context)
        end

        private def process(context)
          matched = Marten.routes.resolve(context.request.path)

          handler = matched.handler.new(context.marten.request, matched.kwargs)
          context.marten.response = handler.process_dispatch.as(HTTP::Response)

          context
        end
      end
    end
  end
end
