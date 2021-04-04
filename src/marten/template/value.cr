module Marten
  module Template
    # A template value.
    class Value
      alias Raw = Array(Value) | Bool | Float64 | Hash(Value, Value) | Int32 | Int64 | Iterator(Value) | Nil | String |
                  Time

      # Returns the raw value associated with the template value.
      getter raw

      def self.from(raw)
        case raw
        when Hash, NamedTuple
          new(Hash(Value, Value).new.tap { |values| raw.each { |k, v| values[new(k.to_s)] = from(v) } })
        when Array, Tuple
          new(raw.map { |item| from(item) })
        when Range
          from(raw.to_a)
        when Char
          new(raw.to_s)
        when Raw
          new(raw)
        when Value
          raw
        else
          raise Errors::UnsupportedValue.new("Unable to initialize template values from #{raw.class} objects")
        end
      end

      def initialize(@raw : Raw)
      end

      def [](key : String) : Value
        self.class.from(resolve_attribute(key))
      end

      def ==(other : Value)
        @raw == other.raw
      end

      def ==(other)
        @raw == other
      end

      # :nodoc:
      def to_s(io)
        @raw.to_s(io)
      end

      private def resolve_attribute(key)
        object = raw
        if object.responds_to?(:[]) && !object.is_a?(Array) && !object.is_a?(String)
          begin
            return object[key.to_s]
          rescue KeyError
          end
        end

        raise Errors::UnknownVariable.new
      end
    end
  end
end
