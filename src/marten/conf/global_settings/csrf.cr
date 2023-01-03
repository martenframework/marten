module Marten
  module Conf
    class GlobalSettings
      # Defines configuration options related to Cross Site Request Forgery protection.
      class CSRF
        @cookie_domain : String? = nil
        @cookie_http_only : Bool = false
        @cookie_max_age : Int32 = 31_556_952
        @cookie_name : String = "csrftoken"
        @cookie_same_site : String = "Lax"
        @cookie_secure : Bool = false
        @protection_enabled : Bool = true
        @exactly_defined_trusted_origins : Array(String)? = nil
        @trusted_origins : Array(String) = [] of String
        @trusted_origins_hosts : Array(String)? = nil
        @trusted_origin_subdomains_per_scheme : Hash(String, Array(String))? = nil

        # Returns the domain to use when setting the CSRF cookie.
        getter cookie_domain

        # Returns a boolean indicating whether client-side scripts should have access to the CSRF token cookie.
        getter cookie_http_only

        # Returns the max age (in seconds) of the CSRF cookie.
        #
        # By default, CSRF cookie max age is set to `31556952` (approximatively one year).
        getter cookie_max_age

        # Returns the name of the cookie to use for the CSRF token (defaults to `"csrftoken"`).
        getter cookie_name

        # Returns the value of the SameSite flag to use for the CSRF cookie (defaults to `"Lax"`).
        getter cookie_same_site

        # Returns a boolean indicating whether to use a secure cookie for the CSRF cookie.
        getter cookie_secure

        # Returns a boolean indicating if CSRF protection is enabled globally (defaults to `true`).
        getter protection_enabled

        # Returns the array of CSRF-trusted origins.
        getter trusted_origins

        # Allows to set the domain to use when setting the CSRF cookie.
        setter cookie_domain

        # Allows to set whether client-side scripts should have access to the CSRF token cookie.
        setter cookie_http_only

        # Allows to set the max age (in seconds) of the CSRF cookie.
        setter cookie_max_age

        # Allows to set the value of the SameSite flag to use for the CSRF cookie.
        setter cookie_same_site

        # Allows to set whether secure cookies should be used for CSRF cookies.
        setter cookie_secure

        # Allows to set whether or not CSRF protection is enabled globally.
        setter protection_enabled

        # Allows to set the name of the cookie to use for the CSRF token.
        def cookie_name=(name : String | Symbol)
          @cookie_name = name.to_s
        end

        # Allows to define an array of trusted origins.
        #
        # These origins will be trusted for CSRF-protected requests (such as POST requests) and they will be used to
        # check either the `Origin` or the `Referer` header depending on the request scheme. This is done to ensure that
        # a specific subdomain such as `sub1.example.com` cannot issue a POST request to `sub2.example.com`. In order to
        # enable CSRF-protected requests over different origins, it's possible to add trusted origins to this array. For
        # example `https://sub1.example.com` can be configured as a trusted domain that way, but it's possible to allow
        # CSRF-protected requests for all the subdomains of a specific domain by using `https://*.example.com`.
        def trusted_origins=(origins : Array(String))
          @exactly_defined_trusted_origins = nil
          @trusted_origins_hosts = nil
          @trusted_origin_subdomains_per_scheme = nil
          @trusted_origins = origins
        end

        protected def exactly_defined_trusted_origins
          @exactly_defined_trusted_origins ||= trusted_origins.reject(&.includes?('*'))
        end

        protected def trusted_origins_hosts
          @trusted_origins_hosts ||= trusted_origins.compact_map do |origin|
            parsed_origin = URI.parse(origin)
            next if parsed_origin.host.nil?
            parsed_origin.host.not_nil!.lstrip('*')
          end
        end

        protected def trusted_origin_subdomains_per_scheme
          @trusted_origin_subdomains_per_scheme ||= begin
            h = Hash(String, Array(String)).new

            trusted_origins.each do |origin|
              next unless origin.includes?('*')
              parsed_origin = URI.parse(origin)
              h[parsed_origin.scheme.not_nil!] ||= [] of String
              h[parsed_origin.scheme.not_nil!] << parsed_origin.host.not_nil!.lstrip('*')
            end

            h
          end
        end
      end
    end
  end
end
