require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `unless` template tag.
      # `
      # The `unless` template tags allows to define conditions allowing to control which blocks should be executed. An
      # unless tag must always start with an `unless` condition, followed by an optional (and final) `else` block.
      class Unless < Base
        include CanSplitSmartly

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)[1..]

          # The idea is to build an array of <condition, nodeset> tuples by respecting the order of an unless/else
          # condition. The first tuple in the array will correspond to the unless condition and the associated nodeset
          # while the last tuple in the array (if the array size is greater than one) will correspond to the else and
          # the corresponding nodeset.
          @conditions_and_nodes = [] of Tuple(Condition::Token::Base?, NodeSet)

          # First step: unless condition.
          condition = Condition.new(parts).parse
          inner_nodes = parser.parse(up_to: {ELSE_PART, ENDUNLESS_PART})
          @conditions_and_nodes << {condition, inner_nodes}

          # Final step: optional else condition.
          token = parser.shift_token
          if token.content.starts_with?(ELSE_PART)
            inner_nodes = parser.parse(up_to: {ENDUNLESS_PART})
            @conditions_and_nodes << {nil, inner_nodes}
            token = parser.shift_token
          end

          if token.content != ENDUNLESS_PART
            raise Errors::InvalidSyntax.new("Unclosed unless block")
          end
        end

        def render(context : Context) : String
          @conditions_and_nodes.each do |condition, inner_nodes|
            condition_matched = condition.nil? || !condition.eval(context).truthy?
            return inner_nodes.render(context) if condition_matched
          end

          ""
        end

        private ELSE_PART      = "else"
        private ENDUNLESS_PART = "endunless"
      end
    end
  end
end
