require "./concerns/view_response_converter"

module Marten
  module Server
    module Handlers
      class Response
        include ::HTTP::Handler
        include ViewResponseConverter

        def call(context : ::HTTP::Server::Context)
          process(context)
        end

        private def process(context)
          response = context.marten.response
          return context if response.nil?

          convert_view_response(context, response)

          context
        end
      end
    end
  end
end
