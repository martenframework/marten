module Marten
  module HTTP
    class Response
      class SeeOther < Response
        def initialize(
          location : String,
          content : String = "",
          content_type : String = DEFAULT_CONTENT_TYPE
        )
          super(content: content, content_type: content_type, status: 303)
          self["Location"] = location
        end
      end
    end
  end
end
