module Marten
  abstract class Middleware
    # Sets the X-Frame-Options header in the response if it wasn't already set.
    #
    # When this middleware is used, a X-Frame-Options header will be inserted into the HTTP response. The default value
    # for this header (configurable in the `x_frame_options` setting) is "DENY", which means that the response cannot be
    # displayed in a frame. This allows to prevent click-jacking attacks, by ensuring that the web app cannot be
    # embedded into other sites.
    #
    # On the other hand, if the `x_frame_options` is set to "SAMEORIGIN" the page can be displayed in a frame if the
    # site including is the same as the one serving the page.
    class XFrameOptions < Middleware
      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        response = get_response.call

        # Avoids patching the response if it already contains the X-Frame-Options header.
        return response if response.headers[:"X-Frame-Options"]?

        # Avoids patching the response if it was marked as exempted from using the X-Frame-Options header.
        if response.headers[:"X-Frame-Options-Exempt"]?
          response.headers.delete(:"X-Frame-Options-Exempt")
          return response
        end

        # Inserts the X-Frame-Options header based on the related setting value.
        response.headers[:"X-Frame-Options"] = Marten.settings.x_frame_options.upcase

        response
      end
    end
  end
end
