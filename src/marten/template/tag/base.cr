module Marten
  module Template
    module Tag
      # The template tag base class.
      #
      # Template tags allow to implement complex logics and control flows such as for loop, if blocks, etc. They use the
      # `{% tag %}` syntax and are rendered inside a template for a given context.
      abstract class Base
        def initialize(parser : Parser, source : String)
        end

        # Render the template tag for a given context.
        abstract def render(context : Context) : String
      end
    end
  end
end
