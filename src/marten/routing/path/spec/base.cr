module Marten
  module Routing
    module Path
      module Spec
        # Represents the base path specification.
        abstract class Base
          # Resolves the path against the path specification.
          abstract def resolve(path : String) : Path::Match?

          # Returns a reverser for the path specification.
          abstract def reverser(name : String) : Reverser
        end
      end
    end
  end
end
