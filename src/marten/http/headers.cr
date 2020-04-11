module Marten
  module HTTP
    # Represents a set of HTTP headers extracted from an HTTP request.
    class Headers
      def initialize(@headers : ::HTTP::Headers)
      end

      # Returns the first value associated with the passed header name.
      def [](name : String | Symbol)
        @headers[name.to_s]
      end

      # Returns the first value associated with the passed header name or `nil` if the header is not present.
      def []?(name : String | Symbol)
        @headers[name.to_s]?
      end

      # Returns `true` if the header with the provided name exists.
      def has_key?(name : String | Symbol) # ameba:disable Style/PredicateName
        @headers.has_key?(name.to_s)
      end

      # Returns the value of the specified header name or fallback to the provided default value ( which is `nil`by
      # default).
      def fetch(name : String | Symbol, default = nil)
        @headers.fetch(name.to_s, default)
      end

      # Returns the number of headers.
      delegate size, to: @headers
    end
  end
end
