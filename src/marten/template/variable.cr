module Marten
  module Template
    # A template variable.
    #
    # A template variable's value access such as "foo.bar". It can also correspond to a literal value such as '42' or
    # '"hello"'.
    class Variable
      @literal : Float32 | Float64 | Int32 | Int64 | Nil | String = nil
      @lookups : Array(String)? = nil

      def initialize(raw : String)
        # First try to see if the raw variable is a literal integer.
        begin
          @literal = raw.to_i
        rescue ArgumentError
        end

        # Then try to see uf the raw variable is a literal float.
        if @literal.nil?
          begin
            @literal = raw.to_f
          rescue ArgumentError
          end
        end

        # Then, try to see if it is a literal string (single-quoted or double-quoted) and otherwise consider that it is
        # a standard variable access.
        if @literal.nil? && ['\'', '"'].includes?((quote_char = raw[0])) && quote_char == raw[-1]
          @literal = raw[1..-2].gsub(%{\\#{quote_char}}, quote_char)
        else
          @lookups = raw.split(ATTRIBUTE_SEPARATOR)
        end
      end

      def resolve(context : Context) : Value
        return Value.from(@literal.not_nil!) unless @literal.nil?

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

      private ATTRIBUTE_SEPARATOR = '.'
    end
  end
end
