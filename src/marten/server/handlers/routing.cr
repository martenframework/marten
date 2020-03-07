module Marten
  module Server
    module Handlers
      class Routing
        include ::HTTP::Handler

        def call(context : ::HTTP::Server::Context)
          process(context)
          call_next(context)
        end

        private def process(context)
          matched_rule = Marten.routes.rules.find { |r| r.path == context.request.path }
          return if matched_rule.nil?

          view = matched_rule.view.new
          context.marten.response = view.dispatch(context.marten.request).as(HTTP::Response)
        end
      end
    end
  end
end
