module Marten
  module HTTP
    class Response
      class Forbidden < Response
        override_status 403
      end
    end
  end
end
