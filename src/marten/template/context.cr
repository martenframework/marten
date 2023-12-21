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
      def [](key : String | Symbol) : Value
        @values.reverse_each do |values|
          return values[key.to_s] if values.has_key?(key.to_s)
        end

        raise KeyError.new(key.to_s)
      end

      # Returns a specific context value for a given key or `nil` if not found.
      def []?(key : String | Symbol) : Value?
        self[key.to_s]
      rescue KeyError
        nil
      end

      # Allows to add a new value into the context.
      def []=(key : String | Symbol, value)
        @values.last.not_nil![key.to_s] = Value.from(value)
      end

      # :ditto:
      def []=(key : String | Symbol, value : Value)
        @values.last.not_nil![key.to_s] = value
      end

      # Returns `true` if the context is empty.
      def empty?
        @values.empty? || @values.all?(&.empty?)
      end

      # Merges another context into the current one.
      def merge(other_context : self)
        other_context.values.each do |values|
          @values.last.merge!(values)
        end

        self
      end

      # Merges a hash or a named tuple of context values into the current context.
      def merge(other_context : Hash | NamedTuple)
        other_context.each do |k, v|
          self[k] = v
        end

        self
      end

      # Stack another context hash and yields itself.
      def stack(&)
        @values << Hash(String, Value).new
        yield self
      ensure
        @values.pop
      end

      protected getter values
    end
  end
end
