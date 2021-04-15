require "./parser/**"

module Marten
  module Template
    # The Marten template parser.
    #
    # This class allows to parse a raw template in order to produce a node set. Under the hood, the parser will leverage
    # a lexer (`Marten::Template::Parser::Lexer`) in order to generate a `Marten::Template::NodeSet` object, which
    # contains the set of nodes that were generated from the parsing process. These nodes are all able to be rendered
    # in order to then generate a final output for a given context.
    class Parser
      @tokens : Array(Parser::Token)

      def initialize(@source : String)
        @tokens = Lexer.new(@source).tokenize
      end

      # Generates a set of nodes from the lexical tokens.
      def parse : NodeSet
        nodes = NodeSet.new

        while !@tokens.empty?
          token = @tokens.shift

          if token.type.text?
            nodes.add(Node::Text.new(token.content))
          elsif token.type.variable?
            raise_syntax_error("Empty variable detected on line #{token.line_number}") if token.content.empty?
            nodes.add(Node::Variable.new(token.content))
          end
        end

        nodes
      rescue e : Errors::InvalidSyntax
        if Marten.settings.debug && e.source.nil? && e.token.nil?
          e.source = @source
          e.token = token
        end

        raise e
      end

      private def raise_syntax_error(msg)
        raise Errors::InvalidSyntax.new(msg)
      end
    end
  end
end
