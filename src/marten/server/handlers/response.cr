module Marten
    module Server
      module Handlers
        class Response
          include ::HTTP::Handler

          def call(context : ::HTTP::Server::Context)
            process(context)
          end

          private def process(context)
            response = context.marten.response
            return context if response.nil?

            context.response.status_code = response.status
            context.response.content_type = response.content_type.to_s
            context.response.print(response.content)

            context
          end
        end
      end
    end
  end
