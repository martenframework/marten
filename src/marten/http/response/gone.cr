module Marten
  module HTTP
    class Response
      class Gone < Response
        def initialize(content : String = "", content_type : String = DEFAULT_CONTENT_TYPE)
          super(content: content, content_type: content_type, status: 410)
        end
      end
    end
  end
end
