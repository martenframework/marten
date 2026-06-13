require "./node/**"

module Marten
  module Template
    # Represents a set of nodes.
    #
    # A set of nodes is simply an enumerable holding `Marten::Template::Node` objects. It provides convenient methods
    # allowing to render the underlying nodes.
    class NodeSet
      include Enumerable(Node::Base)

      delegate each, to: @nodes

      def initialize
        @nodes = [] of Node::Base
      end

      # Add a node to the node set.
      def add(node : Node::Base)
        @nodes << node
      end

      # Removes trailing whitespace from the last node if it is a text node.
      def strip_trailing_whitespace
        return if @nodes.empty?

        last_node = @nodes.last
        return unless last_node.is_a?(Node::Text)

        @nodes.pop
        if stripped = last_node.without_trailing_whitespace
          @nodes << stripped
        end
      end

      # Renders the node set for a specific context.
      def render(context : Context)
        String.build do |io|
          each do |node|
            io << node.render(context)
          end
        end
      end
    end
  end
end
