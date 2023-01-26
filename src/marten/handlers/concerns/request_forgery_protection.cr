module Marten
  module Handlers
    # Provides protection against Cross-Site Request Forgeries.
    #
    # This module provides protection against Cross-Site Request Forgeries (CSRF) attacks. CSRF attacks generally
    # involve a malicious website trying to perform actions on a web application on behalf of an already authenticated
    # user.
    #
    # The protection provided by this module works as follows: a CSRF token cookie (generated from a random secret
    # value) is automatically prepared by a `before_dispatch` callback. This token cookie is then sent as part of every
    # HTTP response if the token value was explicitly requested through the use of the `#get_csrf_token` method
    # (otherwise no cookie is set). For each unsafe HTTP method (ie. methods that are not `GET`, `HEAD`, `OPTIONS` or
    # `TRACE`), the module will verify that the CSRF token cookie is available and that a `csrftoken` field is present
    # in the `POST` data hash, or that a `X-CSRF-Token` header is defined. These two token will be verified and they
    # must match; otherwise a 403 error is returned to the user. In addition to that, the module will also verify that
    # the HTTP request host is either part of the allowed hosts (`Marten.settins.allowed_hosts` setting) or that the
    # value of the `Origin` header matches the configured trusted origins (`Marten.settings.csrf.trusted_origins`
    # setting) - in order to protect against cross-subdomain attacks. The `Referer` header will also be checked for
    # HTTPS request (if the `Origin` header is not set) in order to prevent subdomains to perform unsafe HTTP requests
    # on the protected web applications (unless those subdomains are explicitly allowed as part of the
    # `Marten.settings.csrf.trusted_origins` setting).
    #
    # By default, handlers will use the CSRF protection by complying with what is defined as part of the
    # `Marten.settins.csrf.protection_enabled` setting (whose value is `true` by default). It is also possible to
    # override whether or not CSRF protection is used on a per-handler basis by using the `#protect_from_forgery`
    # method.
    module RequestForgeryProtection
      class InvalidTokenFormatError < Exception; end

      macro included
        @@protect_from_forgery : Bool? = nil

        @csrf_token : String? = nil
        @csrf_token_update_required : Bool = false

        extend Marten::Handlers::RequestForgeryProtection::ClassMethods

        before_dispatch :protect_from_forgery
        after_dispatch :persist_new_csrf_token
      end

      module ClassMethods
        # Allows to define whether or not the handler should be protected from Cross-Site Request Forgeries.
        def protect_from_forgery(protect : Bool) : Nil
          @@protect_from_forgery = protect
        end

        # Returns a boolean indicating if the handler is protected from Cross-Site Request Forgeries.
        def protect_from_forgery?
          @@protect_from_forgery.nil? ? Marten.settings.csrf.protection_enabled : @@protect_from_forgery
        end
      end

      # Returns a valid CSRF token to use in the context of the current handler instance.
      #
      # Calling this method will force the CSRF token to be generated if it wasn't set already. It will also result in
      # the token cookie to be set as part of the HTTP response returned by the handler.
      def get_csrf_token
        returned_csrf_token = if csrf_token.nil?
                                gen_new_token
                              else
                                # Re-generate the CSRF token mask so that it varies on each request. This masking is
                                # used to mitigate SSL attacks like BREACH.
                                mask_cipher_secret(unmask_cipher_token(self.csrf_token.not_nil!))
                              end

        self.csrf_token ||= returned_csrf_token
        self.csrf_token_update_required = true

        returned_csrf_token
      end

      private CSRF_SAFE_HTTP_METHODS      = %w(get head options trace)
      private CSRF_SECRET_SIZE            = 32
      private CSRF_TOKEN_ALLOWED_CHARS    = ["-", "_"] + ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      private CSRF_TOKEN_HEADER_NAME      = "X-CSRF-Token"
      private CSRF_TOKEN_INVALID_CHARS_RE = /[^a-zA-Z0-9-_]/
      private CSRF_TOKEN_POST_DATA_NAME   = "csrftoken"
      private CSRF_TOKEN_SIZE             = 64

      private getter csrf_token
      private getter csrf_token_update_required

      private setter csrf_token
      private setter csrf_token_update_required

      private def gen_new_token
        mask_cipher_secret(gen_new_token_secret)
      end

      private def gen_new_token_secret
        Random::Secure.urlsafe_base64(24)
      end

      private def get_expected_token(request)
        # TODO: add support for session-based CSRF tokens.

        token = begin
          request.cookies[Marten.settings.csrf.cookie_name]
        rescue KeyError
          return
        end

        verify_token_format(token)

        token
      end

      private def mask_cipher_secret(secret)
        allowed_chars = CSRF_TOKEN_ALLOWED_CHARS
        mask = gen_new_token_secret

        secret_indexes = secret.chars.map { |c| allowed_chars.index!(c.to_s) }
        mask_indexes = mask.chars.map { |c| allowed_chars.index!(c.to_s) }

        pairs = secret_indexes.zip(mask_indexes)
        cipher = pairs.map { |x, y| allowed_chars[(x + y) % allowed_chars.size] }.join

        mask + cipher
      end

      private def origin_trusted?
        origin = request.headers[:ORIGIN]

        # Allowed hosts are trusted origins.
        host_origin = "#{request.scheme}://#{request.host}"
        return true if host_origin == origin

        return true if Marten.settings.csrf.exactly_defined_trusted_origins.includes?(origin)

        parsed_origin = URI.parse(origin)
        return false unless Marten.settings.csrf.trusted_origin_subdomains_per_scheme[parsed_origin.scheme]?

        domain = parsed_origin.host.not_nil!
        Marten.settings.csrf.trusted_origin_subdomains_per_scheme[parsed_origin.scheme].any? do |host_pattern|
          same_domain?(domain, host_pattern)
        end
      rescue HTTP::Errors::UnexpectedHost | NilAssertionError
        false
      end

      private def persist_new_csrf_token
        return unless csrf_token && csrf_token_update_required
        response!.cookies.set(
          name: Marten.settings.csrf.cookie_name,
          value: csrf_token,
          expires: Time.local + Time::Span.new(seconds: Marten.settings.csrf.cookie_max_age),
          domain: Marten.settings.csrf.cookie_domain,
          secure: Marten.settings.csrf.cookie_secure,
          http_only: Marten.settings.csrf.cookie_http_only,
          same_site: Marten.settings.csrf.cookie_same_site
        )
      end

      private def protect_from_forgery
        pre_check_expected_csrf_token = begin
          get_expected_token(request)
        rescue InvalidTokenFormatError
          self.csrf_token_update_required = true
          gen_new_token
        end

        if !pre_check_expected_csrf_token.nil?
          self.csrf_token = pre_check_expected_csrf_token
        end

        # Return early if the current HTTP method is "safe" by definition (ie. according to RFC7231 HTTP methods are
        # safe if their defined semantics are essentially read-only) or if CSRF protection is disable on a per-handler
        # basis.
        return if !self.class.protect_from_forgery? || request.disable_request_forgery_protection?
        return if CSRF_SAFE_HTTP_METHODS.includes?(request.method.downcase)

        if request.headers[:ORIGIN]?
          return reject("Origin '#{request.headers[:ORIGIN]}' is not trusted") unless origin_trusted?
        elsif request.secure?
          # Check the referer for HTTPS requests in order to ensure it matches allowed values. This is not done for HTTP
          # request since the Referer address could be spoofed easily as part of a man-in-the-middle attack.
          return reject("Referer is missing") unless request.headers[:REFERER]?
          return reject("Referer '#{request.headers[:REFERER]}' is not trusted") unless referer_trusted?
        end

        begin
          expected_csrf_token = get_expected_token(request).not_nil!
        rescue error : InvalidTokenFormatError
          return reject(error.message.not_nil!)
        rescue NilAssertionError
          return reject("CSRF token is missing")
        end

        request_csrf_token = nil
        request_csrf_token = request.data.fetch(CSRF_TOKEN_POST_DATA_NAME, nil) if request.post?
        request_csrf_token = request.headers[CSRF_TOKEN_HEADER_NAME]? if request_csrf_token.nil?

        return reject("CSRF token is missing") if request_csrf_token.nil?
        request_csrf_token = request_csrf_token.not_nil!

        begin
          verify_token_format(request_csrf_token.as?(String).not_nil!)
        rescue InvalidTokenFormatError | NilAssertionError
          return reject("Invalid CSRF token format")
        end

        if !Crypto::Subtle.constant_time_compare(
             unmask_cipher_token(request_csrf_token.as(String)),
             unmask_cipher_token(expected_csrf_token)
           )
          reject("Invalid CSRF token")
        end
      end

      def referer_trusted?
        parsed_referer = URI.parse(request.headers[:REFERER])
        return false if parsed_referer.scheme != "https" || parsed_referer.host.nil?

        # Verify if one of the configured trusted origins matches the referer host.
        if Marten.settings.csrf.trusted_origins_hosts.any? { |h| same_domain?(parsed_referer.host.not_nil!, h) }
          return true
        end

        # Otherwise, perform the same check by using the configured cookie domain or the request's validated host.
        parsed_referer_host = parsed_referer.host.not_nil!
        parsed_referer_host += ":#{parsed_referer.port}" if !["80", "443", nil].includes?(parsed_referer.port)
        if Marten.settings.csrf.cookie_domain
          host_pattern = Marten.settings.csrf.cookie_domain.not_nil!
          host_pattern += ":#{request.port}" if !["80", "443"].includes?(request.port)
          same_domain?(parsed_referer_host, host_pattern)
        else
          parsed_referer_host == request.host
        end
      rescue HTTP::Errors::UnexpectedHost | NilAssertionError
        false
      end

      private def reject(message)
        respond(message, content_type: "text/plain", status: 403)
      end

      private def same_domain?(host, host_pattern)
        host_pattern = host_pattern.downcase
        found = (host_pattern == "*")
        found ||= (
          host_pattern[0] == '.' &&
          (host.ends_with?(host_pattern) || host == host_pattern[1...])
        )
        found ||= (host_pattern == host)
        found
      end

      private def unmask_cipher_token(token)
        mask = token[..CSRF_SECRET_SIZE]
        token = token[CSRF_SECRET_SIZE..]

        allowed_chars = CSRF_TOKEN_ALLOWED_CHARS

        token_indexes = token.chars.map { |c| allowed_chars.index!(c.to_s) }
        mask_indexes = mask.chars.map { |c| allowed_chars.index!(c.to_s) }

        pairs = token_indexes.zip(mask_indexes)
        pairs.map { |x, y| allowed_chars[x - y] }.join
      end

      private def verify_token_format(token)
        if token.size != CSRF_TOKEN_SIZE
          raise InvalidTokenFormatError.new("CSRF token does not have the expected size")
        elsif !token.scan(CSRF_TOKEN_INVALID_CHARS_RE).empty?
          raise InvalidTokenFormatError.new("CSRF token contains invalid characters")
        end
      end
    end
  end
end
