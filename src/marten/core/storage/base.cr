module Marten
  module Core
    module Storage
      # Abstract base class representing a file storage.
      abstract class Base
        # Deletes the file associated with the passed `filepath`.
        abstract def delete(filepath : String) : Nil

        # Returns true if the given `filepath` exists.
        abstract def exists?(filepath : String) : Bool

        # Returns an IO for the given `filepath`.
        #
        # Raises `Marten::Core::Storage::Errors::FileNotFound` if the file does not exist.
        abstract def open(filepath : String) : IO

        # Returns the size of a file at a given `filepath`.
        abstract def size(filepath : String) : Int64

        # Returns the URL associated with the passed file name or file path.
        abstract def url(filepath : String) : String

        # Write a file's content into the storage.
        #
        # This is a destructive operation: any existing file with the same `filepath` will be overwritten.
        abstract def write(filepath : String, content : IO) : Nil

        # Save a file content into the storage by taking care of not overwriting any existing file.
        #
        # The method returns the filepath of the saved file.
        def save(filepath : String, content : IO) : String
          filepath = find_available_filepath(filepath)
          write(filepath, content)
          filepath
        end

        private def find_available_filepath(filepath)
          path = Path[filepath]
          stem = path.stem
          extension = path.extension

          while exists?(filepath)
            filepath = gen_unique_filepath(stem, extension)
            filepath = File.join(path.parent.to_s, filepath) if path.parent.to_s != "."
          end

          filepath
        end

        private def gen_unique_filepath(stem, extension)
          String.build do |s|
            s << stem
            s << '_'
            s << Random::Secure.hex(4)
            s << extension
          end
        end
      end
    end
  end
end
