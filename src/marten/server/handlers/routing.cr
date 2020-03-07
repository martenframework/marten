module Marten
  module Server
    module Handlers
      class Routing
        include ::HTTP::Handler

        def call(context : ::HTTP::Server::Context)
          process(context)
        end

        private def process(context)
          matched_rule = Marten.routes.rules.find { |r| r.path == context.request.path }
          return if matched_rule.nil?

          view = matched_rule.view.new
          response = view.dispatch(context.marten.request)

          unless response.nil?
            context.response.status_code = response.status
            context.response.content_type = response.content_type.to_s
            context.response.print(response.content)
          end

          context
        end
      end
    end
  end
end
