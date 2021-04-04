module Marten
  module Template
    # Represents a template filter expression.
    #
    # A filter expression will resolve an expression such as "foo.bar|filter1|filter2", which could contain a variable
    # (whose specific attributes are accessed) to which filters are optionally applied.
    class FilterExpression
      def initialize(@raw_expression : String)
        # TODO: handle filters.
        @variable = Variable.new(@raw_expression)
      end

      def resolve(context : Context)
        @variable.resolve(context)
      end
    end
  end
end
