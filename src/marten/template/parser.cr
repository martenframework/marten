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

      getter encountered_block_names

      def initialize(@source : String)
        @tokens = Lexer.new(@source).tokenize
        @encountered_block_names = [] of String
      end

      # Generates a set of nodes from the lexical tokens.
      def parse(up_to : Array(String) | Nil | Tuple = nil) : NodeSet
        nodes = NodeSet.new

        while !@tokens.empty?
          token = shift_token

          if token.type.text?
            nodes.add(Node::Text.new(token.content))
          elsif token.type.variable?
            raise_syntax_error("Empty variable detected on line #{token.line_number}") if token.content.empty?
            nodes.add(Node::Variable.new(token.content))
          elsif token.type.tag?
            raise_syntax_error("Empty tag detected on line #{token.line_number}") if token.content.empty?

            tag_name = token.content.split.first
            if !up_to.nil? && up_to.includes?(tag_name)
              @tokens.unshift(token)
              return nodes
            end

            nodes.add(Node::Tag.new(self, token.content))
          end
        end

        if !up_to.nil?
          raise_syntax_error("Unclosed tags, expected: #{up_to.join(", ")}")
        end

        nodes
      rescue e : Errors::InvalidSyntax
        if Marten.settings.debug && e.source.nil? && e.token.nil?
          e.source = @source
          e.token = token
        end

        raise e
      end

      # Extracts the next token from the available lexical tokens.
      def shift_token
        @tokens.shift
      end

      private def raise_syntax_error(msg)
        raise Errors::InvalidSyntax.new(msg)
      end
    end
  end
end
