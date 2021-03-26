require "./concerns/view_response_converter"

module Marten
  module Server
    module Handlers
      class Middleware
        include ::HTTP::Handler
        include ViewResponseConverter

        @middleware_chain : Array(Marten::Middleware)?

        def call(context : ::HTTP::Server::Context)
          response : HTTP::Response? = nil

          # Call each middleware in order to let them process the incoming request and optionnaly bypass the routing
          # mechanism by returning an early response.
          middleware_chain.each do |middleware|
            result = middleware.process_request(context.marten.request).as(HTTP::Response?)

            unless result.nil?
              response = result
              break
            end
          end

          # No response means that the next HTTP handler (routing, likely) must be called.
          if response.nil?
            call_next(context)
          end

          response = response.nil? ? context.marten.response : response
          return context if response.nil?

          # Call each middleware in order to let them process the response in order to alter it or completely replace it
          # if applicable.
          middleware_chain.each do |middleware|
            response = middleware.process_response(context.marten.request, response).as(HTTP::Response)
          end

          # At this point the final HTTP response has to be written the server response.
          convert_view_response(context, response)

          context
        end

        private def middleware_chain
          @middleware_chain ||= Marten.settings.middleware.map { |middleware_klass| middleware_klass.new }
        end
      end
    end
  end
end
