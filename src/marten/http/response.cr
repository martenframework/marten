module Marten
  module HTTP
    # Represents an HTTP response.
    #
    # This class allows to manipulate HTTP responses. These objects are associated with a specific HTTP response status,
    # and they can define an associated content (and content type) as well as additional headers.
    class Response
      DEFAULT_CONTENT_TYPE = "text/html"

      # Returns the content associated with the HTTP response.
      getter content

      # Returns the content type associated with the HTTP response.
      getter content_type

      # Returns the cookies associated with the HTTP response.
      getter cookies

      # Returns the headers associated with the HTTP response.
      getter headers

      # Returns the status code of the HTTP response.
      getter status

      # Allows to overridde the response's content.
      setter content

      def initialize(
        @content : String = "",
        @content_type : String = DEFAULT_CONTENT_TYPE,
        @status : Int32 = 200
      )
        @cookies = Cookies.new
        @headers = Headers.new
      end

      # Allows to set a specific header.
      def []=(header : String | Symbol, value)
        headers[header.to_s] = value.to_s
      end
    end
  end
end
