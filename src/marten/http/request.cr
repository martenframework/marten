module Marten
  module HTTP
    # Represents an HTTP request processed by Marten.
    #
    # When a page is request, Marten creates a `Marten::HTTP::Request` that gives access to all the information and
    # metadata of the incoming request.
    class Request
      @accepted_media_types : Array(MIME::MediaType)?
      @content_security_policy : ContentSecurityPolicy?
      @content_security_policy_nonce : String?
      @disable_request_forgery_protection = false
      @flash : FlashStore?
      @host_and_port : NamedTuple(host: String, port: String)?
      @scheme : String?
      @session : Session::Store::Base?

      def initialize(@request : ::HTTP::Request)
        # Overrides the request's body IO object so that it's possible to do seek/rewind operations on it if needed.
        @request.body = IO::Memory.new((request.body || IO::Memory.new).gets_to_end)
      end

      # Returns `true` if the passed media type is accepted by the request.
      def accepts?(media_type : String)
        accepted_media_types.any? { |mt| mt.media_type == "*/*" || mt.media_type == media_type }
      end

      # Returns an array of the media types accepted by the request.
      def accepted_media_types : Array(MIME::MediaType)
        @accepted_media_types ||= begin
          raw_media_types = headers.fetch(:ACCEPT, "*/*")
          raw_media_types.split(',').compact_map do |raw_media_type|
            MIME::MediaType.parse(raw_media_type) unless raw_media_type.strip.empty?
          end
        end
      end

      # Returns the raw body of the request as a string.
      def body : String
        @body ||= @request.body.nil? ? "" : @request.body.as(IO).gets_to_end
      end

      # Returns the content security policy assigned with the request.
      def content_security_policy : ContentSecurityPolicy?
        @content_security_policy
      end

      # Allows to assign a new content security policy to the request (or reset it if the passed value is `nil`).
      def content_security_policy=(content_security_policy : ContentSecurityPolicy?)
        @content_security_policy = content_security_policy
      end

      # Returns the value of a Content-Security-Policy nonce associated with the request.
      def content_security_policy_nonce
        @content_security_policy_nonce ||= Random::Secure.urlsafe_base64(16)
      end

      # Returns the cookies associated with the request.
      def cookies
        @cookies ||= Cookies.new(@request.cookies)
      end

      # Returns the parsed request data.
      def data : Params::Data
        @data ||= Params::Data.new(extract_raw_data_params)
      end

      # Returns `true` if the request is a DELETE.
      def delete?
        method == METHOD_DELETE
      end

      # Returns the flash store for the considered request.
      #
      # If no flash store was previously set (for example if the flash middleware is not used), a `NilAssertionError`
      # exception will be raised.
      def flash
        @flash.not_nil!
      rescue NilAssertionError
        raise Errors::UnmetRequestCondition.new("Flash store not available")
      end

      # Returns `true` if the flash store was properly set for the considered request.
      def flash?
        !@flash.nil?
      end

      # Allows to set the flash store for the request.
      def flash=(flash_store : FlashStore)
        @flash = flash_store
      end

      # Returns the path including the GET parameters if applicable.
      def full_path : String
        @full_path ||= (path + (query_params.empty? ? "" : "?#{@request.query_params}")).as(String)
      end

      # Returns `true` if the request is a GET.
      def get?
        method == METHOD_GET
      end

      # Returns `true` if the request is a HEAD.
      def head?
        method == METHOD_HEAD
      end

      # Returns the HTTP headers embedded in the request.
      def headers : Headers
        @headers ||= Headers.new(@request.headers)
      end

      # Returns the host associated with the considered request.
      def host : String
        host_and_port[:host]
      end

      # Returns a string representation of HTTP method that was used in the request.
      #
      # The returned method name (eg. "GET" or "POST") is completely uppercase.
      def method : String
        @request.method.upcase
      end

      # Returns `true` if the request is an OPTIONS.
      def options?
        method == METHOD_OPTIONS
      end

      # Returns `true` if the request is a PATCH.
      def patch?
        method == METHOD_PATCH
      end

      # Returns the request path as a string.
      #
      # Only the path of the request is included (without scheme or domain).
      def path : String
        @request.path
      end

      # Returns the port associated with the considered request.
      def port : String?
        host_and_port[:port]
      end

      # Returns `true` if the request is a POST.
      def post?
        method == METHOD_POST
      end

      # Returns `true` if the request is a PUT.
      def put?
        method == METHOD_PUT
      end

      # Returns the HTTP GET parameters embedded in the request.
      def query_params : Params::Query
        @query_parans ||= Params::Query.new(extract_raw_query_params)
      end

      # Returns the scheme of the request (either `"http"` or `"https"`).
      def scheme : String
        @scheme ||= begin
          if Marten.settings.use_x_forwarded_proto && headers[:X_FORWARDED_PROTO]? == "https"
            SCHEME_HTTPS
          else
            SCHEME_HTTP
          end
        end
      end

      # Returns `true` if the request is secure (if it is an HTTPS request).
      def secure?
        scheme == SCHEME_HTTPS
      end

      # Returns the session store for the considered request.
      #
      # If no session store was previously set (for example if the session middleware is not set), a `NilAssertionError`
      # exception will be raised.
      def session
        @session.not_nil!
      rescue NilAssertionError
        raise Errors::UnmetRequestCondition.new("Session store not available")
      end

      # Returns `true` if the session store was properly set for the considered request.
      def session?
        !@session.nil?
      end

      # Allows to set the session store for the request.
      def session=(session_store : Session::Store::Base)
        @session = session_store
      end

      # Returns `true` if the request is a TRACE.
      def trace?
        method == METHOD_TRACE
      end

      protected getter? disable_request_forgery_protection

      protected setter disable_request_forgery_protection
      protected setter scheme

      private CONTENT_TYPE_APPLICATION_JSON = "application/json"
      private CONTENT_TYPE_MULTIPART_FORM   = "multipart/form-data"
      private CONTENT_TYPE_URL_ENCODED_FORM = "application/x-www-form-urlencoded"
      private HOST_VALIDATION_RE            = /^([a-z0-9.-]+|\[[a-f0-9]*:[a-f0-9\.:]+\])(:\d+)?$/
      private METHOD_DELETE                 = "DELETE"
      private METHOD_GET                    = "GET"
      private METHOD_HEAD                   = "HEAD"
      private METHOD_OPTIONS                = "OPTIONS"
      private METHOD_PATCH                  = "PATCH"
      private METHOD_POST                   = "POST"
      private METHOD_PUT                    = "PUT"
      private METHOD_TRACE                  = "TRACE"
      private SCHEME_HTTP                   = "http"
      private SCHEME_HTTPS                  = "https"

      private def allowed_host?(domain)
        allowed_hosts.find do |host_pattern|
          next if host_pattern.empty?
          host_pattern = host_pattern.downcase
          found = (host_pattern == "*")
          found ||= (host_pattern[0] == '.' && (domain.ends_with?(host_pattern) || domain == host_pattern[1...]))
          found ||= (host_pattern == domain)
          found
        end
      end

      private def allowed_hosts
        allowed_hosts = Marten.settings.allowed_hosts
        if Marten.settings.debug && Marten.settings.allowed_hosts.empty?
          allowed_hosts = [".localhost", "127.0.0.1", "[::1]"]
        end

        allowed_hosts
      end

      private def content_type?(content_type)
        headers[:CONTENT_TYPE]?.try &.starts_with?(content_type)
      end

      private def extract_and_validate_host_and_port
        if Marten.settings.use_x_forwarded_host && headers.has_key?(:X_FORWARDED_HOST)
          host = headers[:X_FORWARDED_HOST]
        elsif headers.has_key?(:HOST)
          host = headers[:HOST]
        else
          host = nil
        end

        raise Errors::UnexpectedHost.new("No host specified") if host.nil? || host.as(String).empty?

        domain, port = extract_domain_and_port(host)

        if Marten.settings.use_x_forwarded_port &&
           headers.has_key?(:X_FORWARDED_PORT) &&
           !headers[:X_FORWARDED_PORT].empty?
          port = headers[:X_FORWARDED_PORT]
        end

        if port.empty?
          port = secure? ? "443" : "80"
        end

        return {host: host, port: port} if domain && allowed_host?(domain)

        raise Errors::UnexpectedHost.new(
          "Unexpected Host header: #{host}. You may need to add #{host} to the allowed_hosts setting."
        )
      end

      private def extract_domain_and_port(host)
        host = host.downcase

        return {"", ""} unless HOST_VALIDATION_RE.match(host)

        # Identifies an IPv6 address without a port.
        return {host, ""} if host[-1] == ']'

        before_match, match, after_match = host.rpartition(":")

        if match.empty?
          domain = after_match
          port = ""
        else
          domain = before_match
          port = after_match
        end

        # Remove any trailing dot (if the domains ends with a dot).
        domain = domain[...-1] if domain.ends_with?('.')

        return {domain, port}
      end

      private def extract_raw_data_params
        params = Params::Data::RawHash.new

        if content_type?(CONTENT_TYPE_URL_ENCODED_FORM)
          ::HTTP::Params.parse(body) do |key, value|
            params[key] = [] of Params::Data::Value unless params.has_key?(key)
            params[key].as(Params::Data::Values) << value
          end
        elsif content_type?(CONTENT_TYPE_MULTIPART_FORM)
          # Rewind the request's body and parses multipart form data (both regular params and files).
          @request.body.as(IO).rewind
          ::HTTP::FormData.parse(@request) do |part|
            next unless part

            params[part.name] = [] of Params::Data::Value unless params.has_key?(part.name)
            if !part.filename.nil? && !part.filename.not_nil!.empty?
              params[part.name].as(Params::Data::Values) << UploadedFile.new(part)
            else
              params[part.name].as(Params::Data::Values) << part.body.gets_to_end
            end
          end
        elsif content_type?(CONTENT_TYPE_APPLICATION_JSON)
          if !(json_params = JSON.parse(body).as_h?).nil?
            json_params.each do |key, value|
              params[key] = [] of Params::Data::Value unless params.has_key?(key)
              params[key].as(Params::Data::Values) << value
            end
          end
        end

        params
      end

      private def extract_raw_query_params
        params = Params::Query::RawHash.new

        @request.query_params.each do |key, value|
          params[key] = [] of Params::Query::Value unless params.has_key?(key)
          params[key] << value
        end

        params
      end

      private def host_and_port
        @host_and_port ||= extract_and_validate_host_and_port
      end
    end
  end
end
