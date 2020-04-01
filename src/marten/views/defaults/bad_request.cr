module Marten
  module Views
    module Defaults
      class BadRequest < Base
        def dispatch
          HTTP::Response::BadRequest.new(content: "Bad Request", content_type: "text/plain")
        end
      end
    end
  end
end
