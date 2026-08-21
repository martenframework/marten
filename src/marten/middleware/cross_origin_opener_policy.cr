module Marten
  abstract class Middleware
    # Sets the Cross-Origin-Opener-Policy header in the response if it wasn't already set.
    #
    # When this middleware is used, a Cross-Origin-Opener-Policy header will be inserted into the HTTP response. The
    # value for this header is configurable in the `cross_origin_opener_policy` setting. This header allows browsers to
    # isolate a top-level window from other documents by putting them in a different browsing context group, which
    # mitigates cross-origin attacks that rely on `window.opener`.
    #
    # The possible values for the Cross-Origin-Opener-Policy header include:
    # - unsafe-none: Allows the document to be added to its opener's browsing context group unless the opener itself
    #                has a COOP of same-origin or same-origin-allow-popups.
    # - same-origin-allow-popups: Isolates the browsing context to same-origin documents or those which either don't
    #                             set COOP or which opt out of isolation by setting a COOP of unsafe-none.
    # - same-origin: Isolates the browsing context exclusively to same-origin documents. This is the default and most
    #                secure option.
    # - noopener-allow-popups: Isolates the browsing context and always sets `window.opener` to `null` for opened
    #                          documents.
    #
    # It is possible to define a custom header value on a per-handler basis by using the
    # `#cross_origin_opener_policy` method, or to disable the insertion of this header by using the
    # `#exempt_from_cross_origin_opener_policy` method.
    class CrossOriginOpenerPolicy < Middleware
      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        response = get_response.call

        # Avoids patching the response if it already contains the Cross-Origin-Opener-Policy header.
        return response if response.headers[:"Cross-Origin-Opener-Policy"]?

        # Avoids patching the response if it was marked as exempted from using the Cross-Origin-Opener-Policy header.
        if response.headers[:"Cross-Origin-Opener-Policy-Exempt"]?
          response.headers.delete(:"Cross-Origin-Opener-Policy-Exempt")
          return response
        end

        response.headers[:"Cross-Origin-Opener-Policy"] = Marten.settings.cross_origin_opener_policy

        response
      end
    end
  end
end
