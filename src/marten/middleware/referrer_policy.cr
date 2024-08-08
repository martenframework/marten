module Marten
  abstract class Middleware
    # Sets the Referrer-Policy header in the response if it wasn't already set.
    #
    # When this middleware is used, a Referrer-Policy header will be inserted into the HTTP response. The value for this
    # header is configurable in the `referrer_policy` setting. This header controls how much referrer information should
    # be included with requests made from your website to other origins. By setting this header, you can enhance the
    # privacy and security of your users by limiting the amount of information that is sent with outbound requests.
    #
    # The possible values for the Referrer-Policy header include:
    # - no-referrer: The Referer header will be omitted entirely. No referrer information is sent with requests.
    # - no-referrer-when-downgrade: The Referer header will not be sent to less secure destinations
    #                               (e.g., from HTTPS to HTTP), but will be sent to same or more secure destinations.
    # - origin: Only the origin of the document is sent as the referrer.
    # - origin-when-cross-origin: The full URL is sent as the referrer when performing a same-origin request,
    #                             but only the origin is sent for cross-origin requests.
    # - same-origin: The Referer header is sent with same-origin requests, but not with cross-origin requests.
    # - strict-origin: Only the origin is sent as the referrer, and only for same-origin requests.
    # - strict-origin-when-cross-origin: The full URL is sent as the referrer when performing a same-origin request,
    #                                    but only the origin is sent for cross-origin requests.
    #                                    No referrer information is sent to less secure destinations.
    # - unsafe-url: The full URL is always sent as the referrer, regardless of the request's security.
    #
    # You can configure the desired policy in the `referrer_policy` setting in your application's configuration.
    class ReferrerPolicy < Middleware
      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        response = get_response.call

        # Don't change the Referrer-Policy if it is already set
        return response if response.headers[:"Referrer-Policy"]?

        # Set the Referrer-Policy according to settings
        response.headers[:"Referrer-Policy"] = Marten.settings.referrer_policy

        response
      end
    end
  end
end
