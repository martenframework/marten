module Marten
  module HTTP
    class Response
      class Found < Response
        def initialize(
          location : String,
          content : String = "",
          content_type : String = DEFAULT_CONTENT_TYPE
        )
          super(content: content, content_type: content_type, status: 302)
          self["Location"] = location
        end
      end
    end
  end
end
