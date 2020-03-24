module Marten
  module Views
    module Defaults
      class PageNotFound < Base
        def dispatch
          HTTP::Response::NotFound.new(content: "The requested resource was not found.", content_type: "text/plain")
        end
      end
    end
  end
end
