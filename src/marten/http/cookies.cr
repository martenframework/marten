module Marten
  module HTTP
    # Represents a set of cookies.
    class Cookies
      include Enumerable({String, Array(String)})

      def initialize(@cookies : ::HTTP::Cookies)
      end

      def initialize
        @cookies = ::HTTP::Cookies.new
      end

      # Returns true if the other cookies object corresponds to the current cookies.
      def ==(other : self)
        super || (to_stdlib == other.to_stdlib)
      end

      # Returns the value associated with the passed cookie name.
      def [](name : String | Symbol)
        cookies[name.to_s].value
      end

      # Returns the value associated with the passed cookie name or `nil` if the cookie is not present.
      def []?(name : String | Symbol)
        cookies[name.to_s]?.try(&.value)
      end

      def each
        cookies.each do |cookie|
          yield({cookie.name, cookie.value})
        end
      end

      # Returns the value associated with the passed cookie name, or the passed `default` if the cookie is not present.
      def fetch(name : String | Symbol, default)
        fetch(name) { default }
      end

      # Returns the value associated with the passed cookie name, or calls the block with the name when not found.
      def fetch(name : String | Symbol)
        self[name]? || yield name
      end

      # Returns `true` if the cookie with the provided name exists.
      def has_key?(name : String | Symbol) # ameba:disable Style/PredicateName
        cookies.has_key?(name.to_s)
      end

      # Returns `true` if there are no cookies.
      delegate empty?, to: cookies

      # Returns the number of cookies.
      delegate size, to: cookies

      protected def to_stdlib
        cookies
      end

      private getter cookies
    end
  end
end
