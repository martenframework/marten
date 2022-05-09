module Marten
  module Core
    module Storage
      module Errors
        # Represents an error raised when a file cannot be found by a storage.
        class FileNotFound < Exception; end
      end
    end
  end
end
