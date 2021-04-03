module Marten
  module Template
    # A compiled template.
    class Template
      @node_set : NodeSet

      def initialize(source : String)
        @node_set = Parser.new(source).parse
      end

      # Renders the template for a specific context.
      def render(context : Context?) : String
        @node_set.render(context || Context.new)
      end

      # :ditto:
      def render(context : Hash) : String
        render(Context.from_hash(context))
      end
    end
  end
end
