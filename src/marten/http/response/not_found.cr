module Marten
  module HTTP
    class Response
      class NotFound < Response
        override_status 404
      end
    end
  end
end
