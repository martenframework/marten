module Marten
  module HTTP
    class Response
      class NotAllowed < Response
        def initialize(
          allowed_methods : Array(String),
          content : String = "",
          content_type : String = DEFAULT_CONTENT_TYPE
        )
          super(content: content, content_type: content_type, status: 405)
          self["Allow"] = allowed_methods.join(", ") { |m| m.upcase }
        end
      end
    end
  end
end
