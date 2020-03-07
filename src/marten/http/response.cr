module Marten
  module HTTP
    class Response
      getter content
      getter content_type
      getter status

      def initialize(
        @content : String = "",
        @content_type : String | Symbol = "text/html",
        @status : Int32 = 200
      )
      end
    end
  end
end
