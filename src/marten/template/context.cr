module Marten
  module Template
    # A template context.
    class Context
      @values : Hash(String, Value) = Hash(String, Value).new

      # Initializes a context from a hash or a named tuple.
      def self.from(values : Hash | NamedTuple)
        new(Hash(String, Value).new.tap { |ctx_values| values.each { |k, v| ctx_values[k.to_s] = Value.from(v) } })
      end

      def initialize
      end

      def initialize(@values : Hash(String, Value))
      end

      # Returns a specific context value for a given key.
      def [](key : String) : Value
        @values[key]
      end
    end
  end
end
