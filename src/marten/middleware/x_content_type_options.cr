module Marten
  abstract class Middleware
    # Sets the X-Content-Type-Options header in the response if it wasn't already set.
    #
    # When this middleware is used, an `X-Content-Type-Options: nosniff` header will be inserted into the HTTP response
    # unless that header is already present. This instructs browsers to always use the declared `Content-Type` instead
    # of MIME-sniffing the response body, which helps mitigate certain cross-site scripting attacks involving
    # mislabeled or user-uploaded content.
    #
    # It is possible to disable the insertion of this header on a per-handler basis by using the
    # `#exempt_from_x_content_type_options` method.
    class XContentTypeOptions < Middleware
      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        response = get_response.call

        # Avoids patching the response if it already contains the X-Content-Type-Options header.
        return response if response.headers[:"X-Content-Type-Options"]?

        # Avoids patching the response if it was marked as exempted from using the X-Content-Type-Options header.
        if response.headers[:"X-Content-Type-Options-Exempt"]?
          response.headers.delete(:"X-Content-Type-Options-Exempt")
          return response
        end

        response.headers[:"X-Content-Type-Options"] = HEADER_VALUE

        response
      end

      private HEADER_VALUE = "nosniff"
    end
  end
end
