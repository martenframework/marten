module Marten
  module Template
    # A template variable.
    #
    # A template variable's value access such as "foo.bar".
    class Variable
      @lookups : Array(String)

      def initialize(raw : String)
        # TODO: handle literals
        @lookups = raw.split(ATTRIBUTE_SEPARATOR)
      end

      def resolve(context : Context)
        current = nil

        @lookups.each_with_index do |bit, i|
          current = if i == 0
                      context[bit]
                    else
                      current.not_nil![bit]
                    end
        rescue Errors::UnknownVariable
          raise Errors::UnknownVariable.new("Failed lookup for attribute '#{bit}' in '#{current}")
        end

        current.not_nil!
      end

      private ATTRIBUTE_SEPARATOR = '.'
    end
  end
end
