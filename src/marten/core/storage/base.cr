module Marten
  module Core
    module Storage
      # Abstract base class representing a file storage.
      abstract class Base
        # Returns true if the given `filepath` exists.
        abstract def exists?(filepath : String) : Bool

        # Returns an IO for the given `filepath`.
        #
        # Raises `Marten::Core::Storage::Errors::FileNotFound` if the file does not exist.
        abstract def open(filepath : String) : IO

        # Saves a file content into the storage.
        abstract def save(filepath : String, content : IO) : Nil

        # Returns the URL associated with the passed file name or file path.
        abstract def url(filepath : String) : String
      end
    end
  end
end
