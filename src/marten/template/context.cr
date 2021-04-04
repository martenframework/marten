module Marten
  module Template
    # A template context.
    class Context
      @values : Hash(String, Value) = Hash(String, Value).new

      # Initializes a context from a hash or a named tuple.
      def self.from(values : Hash | NamedTuple)
        new(Hash(String, Value).new.tap { |ctx_values| values.each { |k, v| ctx_values[k.to_s] = Value.from(v) } })
      end

      # Allows to initialize an empty context.
      def initialize
      end

      # Allows to initialize a new context from the specified values.
      def initialize(@values : Hash(String, Value))
      end

      # Returns a specific context value for a given key.
      def [](key : String) : Value
        @values[key]
      end

      # Allows to add a new value into the context.
      def []=(key : String, value)
        @values[key] = Value.from(value)
      end

      # :ditto:
      def []=(key : String, value : Value)
        @values[key] = value
      end

      # Returns `true` if the context is empty.
      def empty?
        @values.empty?
      end
    end
  end
end
