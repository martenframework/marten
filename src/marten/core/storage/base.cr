module Marten
  module Core
    module Storage
      # Abstract base class representing a file storage.
      abstract class Base
        # Returns the URL associated with the passed file name or file path.
        abstract def url(filepath : String) : String
      end
    end
  end
end
