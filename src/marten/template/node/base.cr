module Marten
  module Template
    module Node
      # The node abstract base class.
      #
      # A template node is the result of the template parsing process and is able to be rendered in order to produce a
      # specific output (depending on the type of node).
      abstract class Base
        # Given a `Marten::Template::Context` object, generates a `String` output.
        abstract def render(context : Context) : String
      end
    end
  end
end
