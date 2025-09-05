module Marten
  module Template
    # A template value.
    class Value
      include Comparable(self)
      include Enumerable(self)

      alias Raw = Array(Value) | Bool | Float64 | Hash(Value, Value) | Int32 | Int64 | Iterator(Value) |
                  Marten::DB::Field::Any | Marten::DB::Model | Marten::Schema | Marten::Schema::BoundField |
                  Marten::Schema::Field::Base | Marten::Template::Object | Nil | SafeString |
                  String | Time | Time::Span | Handlers::Base | Emailing::Email

      # Returns the raw value associated with the template value.
      getter raw

      def self.from(raw)
        case raw
        when Hash, NamedTuple
          new(Hash(Value, Value).new.tap { |values| raw.each { |k, v| values[new(k.to_s)] = from(v) } })
        when Array, Tuple
          new(raw.map { |item| from(item).as(Value) }.to_a)
        when Range
          from(raw.to_a)
        when Char
          new(raw.to_s)
        when Enum
          new(
            Marten::Template::Object::Enum.new(
              enum_class_name: raw.class.name,
              enum_value_names: raw.class.values.map(&.to_s),
              name: raw.to_s,
              value: raw.to_i64
            )
          )
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

      def <=>(other : Value)
        raw_value = raw
        other_value = other.raw

        if raw_value.is_a?(Number) && other_value.is_a?(Number)
          raw_value <=> other_value
        else
          raise Errors::UnsupportedType.new("Unable to compare #{raw.class} objects with #{other_value.class} objects")
        end
      end

      def each(&)
        yield_each_from_raw { |r| yield Value.from(r) }
      end

      # Returns `true` if the value is empty.
      def empty?
        if (object = raw).responds_to?(:empty?)
          return object.empty?
        end

        false
      end

      # :nodoc:
      def to_s(io)
        @raw.to_s(io)
      end

      # Returns `true` if the value is truthy (ie. if it is not `false`, `0`, or `nil`).
      def truthy?
        !(@raw == false || @raw == 0 || @raw.nil?)
      end

      private def resolve_attribute(key)
        object = raw

        attempt_attribute_resolution_after_failed_collection_lookup = false

        if object.responds_to?(:[]) && !object.is_a?(Array) && !object.is_a?(String) &&
           !object.is_a?(Marten::Template::Object)
          begin
            return object[key.to_s]
          rescue KeyError
            attempt_attribute_resolution_after_failed_collection_lookup = true
          end
        elsif object.is_a?(Indexable) && !object.is_a?(Marten::Template::Object) && key.responds_to?(:to_i)
          begin
            return object[key.to_i]
          rescue ArgumentError | IndexError
            attempt_attribute_resolution_after_failed_collection_lookup = true
          end
        elsif object.responds_to?(:resolve_template_attribute)
          return object.resolve_template_attribute(key.to_s)
        end

        if attempt_attribute_resolution_after_failed_collection_lookup
          res = object.responds_to?(:resolve_template_attribute) ? object.resolve_template_attribute(key.to_s) : nil
          return res if !res.nil?
        end

        raise Errors::UnknownVariable.new
      end

      private def yield_each_from_raw(&)
        case object = raw
        when Enumerable(Value), Iterable(Value)
          object.each { |v| yield v.as(Value).raw }
        when Enumerable, Iterable
          object.each { |v| yield v }
        else
          raise Errors::UnsupportedType.new("#{object.class} objects are not iterable")
        end
      end
    end
  end
end
