module Marten
  module Views
    module Defaults
      class PermissionDenied < Base
        def dispatch
          HTTP::Response::Forbidden.new(content: "403 Forbidden", content_type: "text/plain")
        end
      end
    end
  end
end
