module Marten
  module HTTP
    class Response
      # Represents a streaming HTTP response, with an iterator of strings as a content.
      class Streaming < Response
        # Returns the response's content iterator.
        getter streamed_content

        # Allows to override the response's content iterator.
        setter streamed_content

        def initialize(
          @streamed_content : Iterator(String),
          @content_type : String = DEFAULT_CONTENT_TYPE,
          @status : Int32 = 200
        )
          super(content: "", content_type: @content_type, status: @status)
        end

        def content
          raise NotImplementedError.new(
            "This response has no content, please use the #streamed_content method instead."
          )
        end

        def content=(val)
          raise NotImplementedError.new(
            "This response has no content, please use the #streamed_content= method instead."
          )
        end
      end
    end
  end
end
