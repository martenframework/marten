module Marten
  module HTTP
    class Response
      class ServerError < Response
        def initialize(content : String = "", content_type : String = "text/html")
          super(content: content, content_type: content_type, status: 500)
        end
      end
    end
  end
end
