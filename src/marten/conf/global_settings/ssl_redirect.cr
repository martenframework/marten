module Marten
  module Conf
    class GlobalSettings
      # Allows to configure SSL redirect-related settings.
      class SSLRedirect
        @exempted_paths = [] of Regex | String
        @host : String? = nil

        # Returns an array of paths that should be exempted from HTTPS redirects.
        getter exempted_paths

        # Returns the host that should be used when redirecting non-HTTPS requests.
        getter host

        # Allows to set the host that should be used when redirecting non-HTTPS requests.
        #
        # If set to `nil`, the HTTPS redirect will be performed using the request's host.
        setter host

        # Allows to set the array of paths that should be exempted from HTTPS redirects.
        #
        # Both strings and regexes are accepted.
        def exempted_paths=(paths : Array(Regex) | Array(String) | Array(Regex | String))
          @exempted_paths = [] of Regex | String
          @exempted_paths += paths
        end
      end
    end
  end
end
