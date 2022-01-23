module Marten
  module HTTP
    class Response
      class InternalServerError < Response
        override_status 500
      end
    end
  end
end
