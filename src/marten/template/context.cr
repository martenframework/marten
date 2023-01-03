module Marten
  module Template
    # A template context.
    class Context
      @values : Deque(Hash(String, Value)) = Deque{Hash(String, Value).new}

      # Returns the blocks stack associated with the context.
      getter blocks

      # Initializes a context from a hash or a named tuple.
      def self.from(values : Context | Hash | NamedTuple | Nil)
        context = from_raw_values(values)
        apply_context_producers(context)
        context
      end

      # Initializes a context from a hash (or a named tuple) and an HTTP request.
      def self.from(values : Context | Hash | NamedTuple | Nil, request : HTTP::Request)
        context = from_raw_values(values)
        apply_context_producers(context, request)
        context
      end

      private def self.apply_context_producers(context, request = nil)
        Marten.templates.context_producers.each do |context_producer|
          context_producer.produce(request).try do |result|
            result.each do |k, v|
              context[k.to_s] = v
            end
          end
        end
      end

      private def self.from_raw_values(values)
        case values
        when Context
          values
        when Nil
          new
        else
          new(Hash(String, Value).new.tap { |ctx_values| values.each { |k, v| ctx_values[k.to_s] = Value.from(v) } })
        end
      end

      # Allows to initialize an empty context.
      def initialize
        @blocks = BlockStack.new
      end

      # Allows to initialize a new context from the specified values.
      def initialize(values : Hash(String, Value))
        @values << values
        @blocks = BlockStack.new
      end

      # Returns a specific context value for a given key.
      def [](key : String) : Value
        @values.reverse_each do |values|
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
      def stack(&)
        @values << Hash(String, Value).new
        yield self
      ensure
        @values.pop
      end
    end
  end
end
