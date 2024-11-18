module Marten
  module Routing
    module Path
      # Represents a match result for a path.
      #
      # This struct is returned by the `#resolve` method of a path spec object. It contains the extracted parameters
      # and the end index of the match in the path string.
      struct Match
        getter end_index
        getter parameters

        def initialize(@parameters : MatchParameters, @end_index : Int32)
        end
      end
    end
  end
end
