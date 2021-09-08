module Marten
  module Asset
    module Finder
      # Abstract base class representing an assets finder.
      abstract class Base
        # Returns the absolute path corresponding to the passed file path.
        abstract def find(filepath : String) : String

        # Returns an array of all the available relative and absolute paths for the underlying assets.
        abstract def list : Array({String, String})
      end
    end
  end
end
