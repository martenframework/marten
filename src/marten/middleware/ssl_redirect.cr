module Marten
  abstract class Middleware
    # Redirects all non-HTTPS requests to HTTPS.
    #
    # This middleware will permanently redirect all non-HTTP requests to HTTPS. By default the middleware will redirect
    # to the incoming request's host, but a different host to redirect to can be configured with the `ssl_redirect.host`
    # setting. Additionally, specific request paths can also be exempted from this SSL redirect if the corresponding
    # strings or regexes are specified in the `ssl_redirect.exempted_paths` setting.
    class SSLRedirect < Middleware
      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        if should_redirect?(request)
          return HTTP::Response::MovedPermanently.new(
            "https://#{Marten.settings.ssl_redirect.host || request.host}#{request.full_path}"
          )
        end

        get_response.call
      end

      private def exempted_path?(request : HTTP::Request, exempted_path : Regex)
        Bool
        request.path.matches?(exempted_path)
      end

      private def exempted_path?(request : HTTP::Request, exempted_path : String)
        Bool
        request.path == exempted_path
      end

      private def should_redirect?(request : HTTP::Request) : Bool
        !request.secure? && !Marten.settings.ssl_redirect.exempted_paths.any? { |p| exempted_path?(request, p) }
      end
    end
  end
end
