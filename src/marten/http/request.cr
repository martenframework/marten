module Marten
  module HTTP
    # Represents an HTTP request processed by Marten.
    #
    # When a page is request, Marten creates a `Marten::HTTP::Request` that gives access to all the information and
    # metadata of the incoming request.
    class Request
      @host : String
      @port : Nil | String

      def initialize(@request : ::HTTP::Request)
        @host = extract_and_validate_host
      end

      # Returns the raw body of the request as a string.
      def body : String
        @body ||= @request.body.nil? ? "" : @request.body.as(IO).gets_to_end
      end

      # Returns the path including the GET parameters if applicable.
      def full_path : String
        @full_path ||= (path + (query_params.empty? ? "" : "?#{query_params}")).as(String)
      end

      # Returns the HTTP headers embedded in the request.
      def headers : Headers
        @headers ||= Headers.new(@request.headers)
      end

      # Returns the host associated with the considered request.
      def host : String
        @host
      end

      # Returns a string representation of HTTP method that was used in the request.
      #
      # The returned method name (eg. "GET" or "POST") is completely uppercase.
      def method : String
        @request.method.upcase
      end

      # Returns the request path as a string.
      #
      # Only the path of the request is included (without scheme or domain).
      def path : String
        @request.path
      end

      # Returns the HTTP GET parameters embedded in the request.
      def query_params : QueryParams
        @query_parans ||= QueryParams.new(@request.query_params)
      end

      private HOST_VALIDATION_RE = /^([a-z0-9.-]+|\[[a-f0-9]*:[a-f0-9\.:]+\])(:\d+)?$/

      private def extract_and_validate_host
        if Marten.settings.use_x_forwarded_host && headers.has_key?(:X_FORWARDED_HOST)
          host = headers[:X_FORWARDED_HOST]
        elsif headers.has_key?(:HOST)
          host = headers[:HOST]
        else
          host = nil
        end

        raise Errors::UnexpectedHost.new("No host specified") if host.nil? || host.as(String).empty?

        domain, _ = extract_domain_and_port(host)
        return host if domain && allowed_host?(domain)
        raise Errors::UnexpectedHost.new("Unexpected Host header: #{host}.")
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
    end
  end
end
