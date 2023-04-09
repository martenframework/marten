module Marten
  module Server
    module Handlers
      # Converts Marten HTTP responses to HTTP responses.
      module HandlerResponseConverter
        def convert_handler_response(context : ::HTTP::Server::Context, response : HTTP::Response)
          context.response.status_code = response.status
          context.response.headers.merge!(response.headers.to_stdlib)
          context.response.content_type = response.content_type.to_s

          context.marten.request.cookies.set_cookies.each { |cookie| context.response.cookies << cookie }
          response.cookies.set_cookies.each { |cookie| context.response.cookies << cookie }

          if response.is_a?(HTTP::Response::Streaming)
            # We iterate over the streamed content iterator: at every iteration we write the obtained content to the
            # response and then we call #flush to ensure the client receives the message.
            response.streamed_content.each do |content|
              context.response.print(content)
              context.response.flush
            end
          else
            context.response.print(response.content)
          end
        end
      end
    end
  end
end
