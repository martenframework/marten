module Marten
  module Core
    module Validator
      # URL validator.
      module URL
        extend self

        # Returns `true` if the passed string corresponds to a valid URL.
        def self.valid?(value : String) : Bool
          return false if !(value.chars & UNSAFE_CHARS).empty?

          scheme = value.split(SCHEME_SEPARATOR)[0].downcase
          return false if !ALLOWED_SCHEMES.includes?(scheme)

          begin
            parsed_uri = URI.parse(value)
          rescue URI::Error
            return false
          end

          return false if (parsed_host = parsed_uri.host).nil?

          if !value.match(URL_RE)
            # Attempts to validate possible IDN domains making use of Punycode.
            begin
              ascii_parsed_host = URI::Punycode.to_ascii(parsed_host)
            rescue ArgumentError | NilAssertionError
              return false
            end

            return false if parsed_host == ascii_parsed_host

            parsed_uri.host = parsed_host = ascii_parsed_host
            return false if !parsed_uri.to_s.match(URL_RE)
          end

          # Try to extract a possible IPv4 or IPv6 address from the domain part and validate it.
          if !(matched = parsed_host.match(ADDRESS_LITERAL_PART_RE)).nil?
            return false if !Socket::IPAddress.valid?(matched[1])
          end

          # According to RFC 1034, the maximum length of a full host name is 253 characters. This
          # length restriction is defined as 255 bytes or less, taking into account one byte for the
          # name's length and one byte for the trailing dot used to denote absolute names in DNS.
          return false if parsed_host.size > 253

          true
        end

        private ADDRESS_LITERAL_PART_RE = /^\[(.+)\](?::[0-9]{1,5})?$/i
        private ALLOWED_SCHEMES         = ["http", "https", "ftp", "ftps"]
        private SCHEME_SEPARATOR        = "://"
        private UNICODE_LETTERS_RANGE   = "\u00a1-\uffff"
        private UNSAFE_CHARS            = ['\n', '\t', '\r']

        # The maximum size of a domain name label is 63 characters per RFC 1034 section 3.1.
        private DOMAIN_RE   = /(?:\.(?!-)[a-z#{UNICODE_LETTERS_RANGE}0-9-]{1,63}(?<!-))*/i
        private HOSTNAME_RE = /
          [a-z#{UNICODE_LETTERS_RANGE}0-9]
          (?:[a-z#{UNICODE_LETTERS_RANGE}0-9\-]{0,61}[a-z#{UNICODE_LETTERS_RANGE}0-9])?
          /xi
        private IPV4_RE = /
          (?:0|25[0-5]|2[0-4][0-9]|1[0-9]?[0-9]?|[1-9][0-9]?)
          (?:\.(?:0|25[0-5]|2[0-4][0-9]|1[0-9]?[0-9]?|[1-9][0-9]?)){3}
          /xi
        private IPV6_RE = /\[[0-9a-f\:.]+\]/i
        private TLD_RE  = /\.(?!-)(?:[a-z#{UNICODE_LETTERS_RANGE}-]{2,63}|xn--[a-z0-9]{1,59})(?<!-)\.?/i
        private URL_RE  = /
          ^(?:[a-z0-9.+\-]*)\:\/\/
          (?:[^\s\:@\/]+(?:\:[^\s\:@\/]*)?@)?
          (?:#{IPV4_RE}|#{IPV6_RE}|(#{HOSTNAME_RE}#{DOMAIN_RE}#{TLD_RE}|localhost))
          (?:\:[0-9]{1,5})?
          (?:[\/\?#][^\s]*)?
          \Z
          /xi
      end
    end
  end
end
