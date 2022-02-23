module Marten
  module Conf
    class GlobalSettings
      # Allows to configure sessions-related settings.
      class Sessions
        @cookie_domain : String? = nil
        @cookie_http_only : Bool = false
        @cookie_max_age : Int32 = 1_209_600
        @cookie_name : String = "sessionid"
        @cookie_same_site : String = "Lax"
        @cookie_secure : Bool = false
        @store : String = "cookie"

        # Returns the domain to use when setting the session cookie.
        getter cookie_domain

        # Returns a boolean indicating whether client-side scripts should have access to the session cookie.
        getter cookie_http_only

        # Returns the max age (in seconds) of the session cookie.
        #
        # By default, the session cookie max age is set to `1209600` (two weeks).
        getter cookie_max_age

        # Returns the name of the cookie to use for sessions (defaults to `"sessionid"`).
        getter cookie_name

        # Returns the value of the SameSite flag to use for the session cookie (defaults to `"Lax"`).
        getter cookie_same_site

        # Returns a boolean indicating whether to use a secure cookie for the session cookie.
        getter cookie_secure

        # Returns the identifier of the store that should be used to handle sessions.
        getter store

        # Allows to set the domain to use when setting the session cookie.
        setter cookie_domain

        # Allows to set whether client-side scripts should have access to the session cookie.
        setter cookie_http_only

        # Allows to set the max age (in seconds) of the session cookie.
        setter cookie_max_age

        # Allows to set the value of the SameSite flag to use for the session cookie.
        setter cookie_same_site

        # Allows to set whether secure cookies should be used for session cookies.
        setter cookie_secure

        # Allows to set the name of the cookie to use for sessions.
        def cookie_name=(cookie_name : String | Symbol)
          @cookie_name = cookie_name.to_s
        end

        # Allows to define the store used to handle sessions.
        def store=(store : String | Symbol)
          @store = store.to_s
        end

        # :nodoc:
        def validate : Nil
          unless HTTP::Session::Store.registry.has_key?(store)
            raise Errors::InvalidConfiguration.new("Unknown session store '#{store}'")
          end
        end
      end
    end
  end
end
