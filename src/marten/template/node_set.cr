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
