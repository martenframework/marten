module Marten
  module Views
    module Defaults
      class ServerError < Base
        def dispatch
          HTTP::Response::InternalServerError.new(content: "Internal Server Error", content_type: "text/plain")
        end
      end
    end
  end
end
