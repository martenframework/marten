require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `if` template tag.
      # `
      # The `if` template tags allows to define conditions allowing to control which blocks should be executed. An if
      # tag must always start with an `if` condition, followed by any number of intermediate `elsif` conditions and an
      # optional (and final) `else` block.
      class If < Base
        include CanSplitSmartly

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)[1..]

          # The idea is to build an array of <condition, nodeset> tuples by respecting the order of an if/elsif/else
          # condition. The first tuple in the array will correspond to the if condition and the associated nodeset while
          # the last tuple in the array (if the array size is greater than one) will correspond to the else and the
          # corresponding nodeset. Any intermediary tuples will correspond to intermedia elsif conditions.
          @conditions_and_nodes = [] of Tuple(Condition::Token::Base?, NodeSet)

          # First step: if condition.
          condition = Condition.new(parts).parse
          inner_nodes = parser.parse(up_to: {"elsif", "else", "endif"})
          @conditions_and_nodes << {condition, inner_nodes}

          # Next step: optional elsif conditions.
          token = parser.shift_token
          while token.content.starts_with?("elsif")
            parts = split_smartly(token.content)[1..]
            condition = Condition.new(parts).parse
            inner_nodes = parser.parse(up_to: {"elsif", "else", "endif"})
            @conditions_and_nodes << {condition, inner_nodes}
            token = parser.shift_token
          end

          # Final step: optional else condition.
          if token.content.starts_with?("else")
            inner_nodes = parser.parse(up_to: {"endif"})
            @conditions_and_nodes << {nil, inner_nodes}
            token = parser.shift_token
          end

          if token.content != "endif"
            raise Errors::InvalidSyntax.new("Unclosed if block")
          end
        end

        def render(context : Context) : String
          @conditions_and_nodes.each do |condition, inner_nodes|
            condition_matched = condition.nil? || condition.eval(context).truthy?
            return inner_nodes.render(context) if condition_matched
          end

          ""
        end
      end
    end
  end
end
