module Marten
  module HTTP
    class Response
      class Gone < Response
        override_status 410
      end
    end
  end
end
