module Marten
  module Template
    # A template variable.
    #
    # A template variable's value access such as "foo.bar". It can also correspond to a literal value such as '42' or
    # '"hello"'.
    class Variable
      @literal : Bool | Float32 | Float64 | Int32 | Int64 | Nil | String = nil
      @literal_set : Bool = false
      @lookups : Array(String)? = nil

      def initialize(raw : String)
        if STATIC_LITERAL_MAPPING.has_key?(raw.strip)
          set_literal(STATIC_LITERAL_MAPPING[raw])
        end

        # First try to see if the raw variable is a literal integer.
        if !literal_set?
          begin
            set_literal(raw.to_i)
          rescue ArgumentError
          end
        end

        # Then try to see if the raw variable is a literal float.
        if !literal_set?
          begin
            set_literal(raw.to_f)
          rescue ArgumentError
          end
        end

        # Then, try to see if it is a literal string (single-quoted or double-quoted) and otherwise consider that it is
        # a standard variable access.
        if !literal_set? && ['\'', '"'].includes?((quote_char = raw[0])) && quote_char == raw[-1]
          set_literal(raw[1..-2].gsub(%{\\#{quote_char}}, quote_char))
        end

        if !literal_set?
          @lookups = raw.split(ATTRIBUTE_SEPARATOR)
        end
      end

      def resolve(context : Context) : Value
        return Value.from(@literal) if literal_set?

        current = nil

        @lookups.not_nil!.each_with_index do |bit, i|
          current = if i == 0
                      context[bit]
                    else
                      current.not_nil![bit]
                    end
        rescue KeyError | Errors::UnknownVariable
          return Value.from(nil) unless Marten.settings.templates.strict_variables?

          raise Errors::UnknownVariable.new(
            String.build do |s|
              s << "Failed lookup for attribute '"
              s << bit.to_s
              s << "'"
              s << " in " + current.to_s if current.is_a?(Context)
            end
          )
        end

        current.not_nil!
      end

      private ATTRIBUTE_SEPARATOR    = '.'
      private STATIC_LITERAL_MAPPING = {"nil" => nil, "true" => true, "false" => false}

      private getter? literal_set

      private def set_literal(value)
        @literal = value
        @literal_set = true
      end
    end
  end
end
