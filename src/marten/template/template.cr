module Marten
  module Template
    # A compiled template.
    class Template
      @nodes : NodeSet

      # Returns the nodes corresponding to the parsed template.
      getter nodes

      def initialize(source : String)
        @nodes = Parser.new(source).parse
      end

      # Renders the template for a specific context.
      def render(context : Context? = nil) : String
        @nodes.render(context || Context.new)
      end

      # :ditto:
      def render(context : Hash | NamedTuple) : String
        render(Context.from(context))
      end
    end
  end
end
