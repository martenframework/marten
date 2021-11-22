module Marten
  module Core
    module Storage
      # A basic file system storage that stores files locally.
      class FileSystem < Base
        def initialize(@root : String, @base_url : String)
        end

        def save(filepath : String, content : IO) : Nil
          new_path = File.join(root, filepath)

          FileUtils.mkdir_p(Path[new_path].dirname)

          File.open(new_path, "wb") do |new_file|
            IO.copy(content, new_file)
          end
        end

        def url(filepath : String) : String
          File.join(base_url, URI.encode_path(filepath))
        end

        private getter root
        private getter base_url
      end
    end
  end
end
