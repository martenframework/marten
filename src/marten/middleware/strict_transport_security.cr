module Marten
  abstract class Middleware
    # Sets the Strict-Transport-Security header in the response if it wasn't already set.
    #
    # This middleware automatically sets the HTTP Strict-Transport-Security (HSTS) response header for all responses
    # unless it was already specified in the response headers. This allows to let browsers know that the considered
    # website should only be accessed using HTTPS, which results in future HTTP requests to be automatically converted
    # to HTTPS (up until the configured strict transport policy max age is reached).
    class StrictTransportSecurity < Middleware
      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        response = get_response.call

        return response if Marten.settings.strict_transport_security.max_age.nil?
        return response if !request.secure?

        # Avoids patching the response if it already contains the Strict-Transport-Security header.
        return response if response.headers[:"Strict-Transport-Security"]?

        response.headers[:"Strict-Transport-Security"] = String.build do |s|
          s << "max-age="
          s << Marten.settings.strict_transport_security.max_age.to_s
          s << "; includeSubDomains" if Marten.settings.strict_transport_security.include_sub_domains
          s << "; preload" if Marten.settings.strict_transport_security.preload
        end

        response
      end
    end
  end
end
