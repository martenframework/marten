module Marten
  module HTTP
    class Response
      getter content
      getter content_type
      getter headers
      getter status

      def initialize(
        @content : String = "",
        @content_type : String | Symbol = "text/html",
        @status : Int32 = 200
      )
        @headers = {} of String => String
      end

      def []=(header : String | Symbol, value : Int32 | String | Symbol)
        @headers[header.to_s] = value.to_s
      end
    end
  end
end
