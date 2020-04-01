module Marten
  module HTTP
    class Response
      class BadRequest < Response
        override_status 400
      end
    end
  end
end
