require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `capture` template tag.
      #
      # The `capture` template tags allows to define that the output of a block of code should be stored in a variable:
      #
      # ```
      # {% capture my_var %}
      #   Hello World, {{ name }}!
      # {% endcapture %}
      # ```
      #
      # It is also possible to use the `unless defined` modifier to only assign the variable if it is not already
      # defined in the template context. For example:
      #
      # ```
      # {% capture my_var unless defined %}
      #   Hello World, {{ name }}!
      # {% endcapture %}
      # ```
      class Capture < Base
        include CanSplitSmartly

        @assigned_to : String
        @capture_nodes : NodeSet
        @unless_defined : Bool = false

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size < 2
            raise Errors::InvalidSyntax.new("Malformed capture tag: one variable name must be specified.")
          elsif parts.size == 2
            @assigned_to = parts[1]
          elsif parts.size == 4 && parts[-2..] == UNLESS_DEFINED_PARTS
            @assigned_to = parts[1]
            @unless_defined = true
          else
            raise Errors::InvalidSyntax.new("Malformed capture tag: unrecognized syntax.")
          end

          # Retrieves the inner nodes, up to the `endcapture` tag.
          @capture_nodes = parser.parse(up_to: {"endcapture"})
          parser.shift_token
        end

        def render(context : Context) : String
          if !unless_defined? || !context.has_key?(@assigned_to)
            context[@assigned_to] = @capture_nodes.render(context)
          end

          ""
        end

        private UNLESS_DEFINED_PARTS = ["unless", "defined"]

        private getter? unless_defined
      end
    end
  end
end
