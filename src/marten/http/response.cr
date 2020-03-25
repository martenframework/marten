module Marten
  module HTTP
    class Response
      DEFAULT_CONTENT_TYPE = "text/html"

      getter content
      getter content_type
      getter headers
      getter status

      def initialize(
        @content : String = "",
        @content_type : String = DEFAULT_CONTENT_TYPE,
        @status : Int32 = 200
      )
        @headers = ::HTTP::Headers.new
      end

      def []=(header : String | Symbol, value : Int32 | String | Symbol)
        @headers[header.to_s] = value.to_s
      end
    end
  end
end
