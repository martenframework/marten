module Marten
  module Core
    module Storage
      # A basic file system storage that stores files locally.
      class FileSystem < Base
        def initialize(@root : String, @base_url : String)
        end

        def delete(filepath : String) : Nil
          File.delete(path(filepath))
        rescue File::NotFoundError
          raise Errors::FileNotFound.new("File '#{filepath}' cannot be found")
        end

        def exists?(filepath : String) : Bool
          File.exists?(path(filepath))
        end

        def open(filepath : String) : IO
          File.open(path(filepath), mode: "rb")
        rescue File::NotFoundError
          raise Errors::FileNotFound.new("File '#{filepath}' cannot be found")
        end

        def size(filepath : String) : Int64
          File.size(path(filepath))
        end

        def url(filepath : String) : String
          File.join(base_url, URI.encode_path(filepath))
        end

        def write(filepath : String, content : IO) : Nil
          new_path = path(filepath)

          FileUtils.mkdir_p(Path[new_path].dirname)

          File.open(new_path, "wb") do |new_file|
            IO.copy(content, new_file)
          end
        end

        private getter root
        private getter base_url

        private def path(filepath)
          File.join(root, filepath)
        end
      end
    end
  end
end
