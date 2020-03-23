module Marten
  module Views
    module Defaults
      class ServerError < Base
        def dispatch
          HTTP::Response::ServerError.new(content: "Internal Server Error")
        end
      end
    end
  end
end
