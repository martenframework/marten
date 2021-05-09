module Marten
  module Template
    # A template context.
    class Context
      @values : Array(Hash(String, Value)) = [Hash(String, Value).new]

      # Initializes a context from a hash or a named tuple.
      def self.from(values : Hash | NamedTuple)
        new(Hash(String, Value).new.tap { |ctx_values| values.each { |k, v| ctx_values[k.to_s] = Value.from(v) } })
      end

      # Allows to initialize an empty context.
      def initialize
      end

      # Allows to initialize a new context from the specified values.
      def initialize(values : Hash(String, Value))
        @values = [values]
      end

      # Returns a specific context value for a given key.
      def [](key : String) : Value
        @values.reverse.each do |values|
          return values[key] if values.has_key?(key)
        end

        raise KeyError.new(key)
      end

      # Returns a specific context value for a given key or `nil` if not found.
      def []?(key : String) : Value?
        self[key]
      rescue KeyError
        nil
      end

      # Allows to add a new value into the context.
      def []=(key : String, value)
        @values.last.not_nil![key] = Value.from(value)
      end

      # :ditto:
      def []=(key : String, value : Value)
        @values.last.not_nil![key] = value
      end

      # Returns `true` if the context is empty.
      def empty?
        @values.empty? || @values.all?(&.empty?)
      end

      # Stack another context hash and yields itself.
      def stack : Nil
        @values << Hash(String, Value).new
        yield self
      ensure
        @values.pop
      end
    end
  end
end
