require "./concerns/handler_response_converter"

module Marten
  module Server
    module Handlers
      class Middleware
        include ::HTTP::Handler
        include HandlerResponseConverter

        @middleware_chain : Array(Marten::Middleware)?

        def call(context : ::HTTP::Server::Context)
          # Call each middleware in order to let them process the incoming request and optionnaly bypass the routing
          # mechanism by returning an early response. Each middleware should have access to the final response in order
          # to process it if necessary (or to completely replace it!).
          response : HTTP::Response? = if middleware_chain.empty?
            get_final_response(context)
          else
            middleware_chain.first.chain(context.marten.request, ->{ get_final_response(context) })
          end

          # At this point the final HTTP response has to be written to the server response.
          convert_handler_response(context, response)

          context
        end

        private def get_final_response(context)
          call_next(context)
          context.marten.response.not_nil!
        end

        private def middleware_chain
          @middleware_chain ||= begin
            chain = Marten.settings.middleware.map(&.new)

            chain.each_cons_pair do |middleware, next_middleware|
              middleware.next = next_middleware
            end

            chain
          end
        end
      end
    end
  end
end
