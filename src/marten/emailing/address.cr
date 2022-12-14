module Marten
  module Emailing
    # Represents an email address.
    struct Address
      # Returns the address part of the email address.
      getter address

      # Returns the name part of the email address.
      getter name

      # Returns `true` of the passed string corresponds to a valid email address.
      def self.valid?(value : String) : Bool
        return false if value.empty? || !value.includes?('@')

        user_part, _, domain_part = value.rpartition('@')

        return false unless user_part.match(ADDRESS_USER_PART_RE)

        return true if domain_part == LOCALHOST
        return true if valid_domain?(domain_part) || valid_domain?(URI::Punycode.to_ascii(domain_part))

        false
      end

      private def self.valid_domain?(domain_part)
        return true if domain_part.match(ADDRESS_DOMAIN_PART_RE)

        # Try to extract a possible IPv4 or IPv6 address from the domain part.
        if !(matched = domain_part.match(ADDRESS_LITERAL_PART_RE)).nil?
          return Socket::IPAddress.valid?(matched[1])
        end

        false
      end

      def initialize(@address : String, @name : String? = nil)
      end

      def ==(other : self)
        super || (other.address == address && other.name == name)
      end

      def to_s(io)
        io << (@name.nil? ? @address : %{"#{@name}" <#{@address}>})
      end

      private ADDRESS_DOMAIN_PART_RE  = /^((?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+)(?:[A-Z0-9-]{2,63}(?<!-))\z/i
      private ADDRESS_LITERAL_PART_RE = /\[([A-F0-9:.]+)\]\Z/i
      private ADDRESS_USER_PART_RE    = /
        (
          ^[-!#$%&'*+\/=?^_`{}|~0-9A-Z]+(\.[-!#$%&'*+\/=?^_`{}|~0-9A-Z]+)*\z
          |^"([\001-\010\013\014\016-\037!#-\[\]-\177]|\\[\001-\011\013\014\016-\177])*"\z
        )
        /xi
      private LOCALHOST = "localhost"
    end
  end
end
