module Marten
  abstract class Middleware
    # Sets the Content-Security-Policy header in the response if it wasn't already set.
    #
    # This middleware guarantees the presence of the Content-Security-Policy header in the response's headers. This
    # header provides clients with the ability to limit the allowed sources of different types of content.
    #
    # By default, the middleware will include a Content-Security-Policy header that corresponds to the policy defined in
    # the `content_security_policy` settings. However, if a `Marten::HTTP::ContentSecurityPolicy` object is explicitly
    # assigned to the request object, it will take precedence over the default policy and be used instead.
    class ContentSecurityPolicy < Middleware
      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        response = get_response.call

        # Serving CSP headers along with a 304 Not Modified response can cause issues as the nonces in the updated CSP
        # headers may not align with the nonces in the cached HTML.
        return response if response.status == 304

        # Avoids patching the response if it already contains the Content-Security-Policy or
        # Content-Security-Policy-Report-Only header.
        return response if policy_present?(response)

        # Avoids patching the response if it was marked as exempted from using the Content-Security-Policy header.
        if response.headers[HEADER_NAME_EXEMPT]?
          response.headers.delete(HEADER_NAME_EXEMPT)
          return response
        end

        csp = request.content_security_policy || Marten.settings.content_security_policy.default_policy
        header_name = if Marten.settings.content_security_policy.report_only?
                        HEADER_NAME_REPORT_ONLY
                      else
                        HEADER_NAME
                      end

        response.headers[header_name] = csp.build(
          nonce: request.content_security_policy_nonce,
          nonce_directives: Marten.settings.content_security_policy.nonce_directives
        )

        response
      end

      private HEADER_NAME             = :"Content-Security-Policy"
      private HEADER_NAME_EXEMPT      = :"Content-Security-Policy-Exempt"
      private HEADER_NAME_REPORT_ONLY = :"Content-Security-Policy-Report-Only"

      private def policy_present?(response : HTTP::Response)
        response.headers[HEADER_NAME]? || response.headers[HEADER_NAME_REPORT_ONLY]?
      end
    end
  end
end
