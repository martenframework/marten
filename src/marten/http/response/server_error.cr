module Marten
  module HTTP
    class Response
      class ServerError < Response
        override_status 500
      end
    end
  end
end
