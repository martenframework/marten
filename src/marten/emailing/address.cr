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
        Core::Validator::Email.valid?(value)
      end

      def initialize(@address : String, @name : String? = nil)
      end

      def ==(other : self)
        super || (other.address == address && other.name == name)
      end

      def to_s(io)
        io << (@name.nil? ? @address : %{"#{@name}" <#{@address}>})
      end
    end
  end
end
