module Marten
  module Server
    module Handlers
      module ViewResponseConverter
        private def convert_view_response(context : ::HTTP::Server::Context, response : HTTP::Response)
          context.response.status_code = response.status
          context.response.headers.merge!(response.headers)
          context.response.content_type = response.content_type.to_s
          context.response.print(response.content)
        end
      end
    end
  end
end
