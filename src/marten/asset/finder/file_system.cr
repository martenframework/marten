module Marten
  module Asset
    module Finder
      # Represents an asset finder allowing to find assets in the local file system, in a given directory.
      class FileSystem < Base
        getter root

        def initialize(@root : String)
        end

        def find(filepath : String) : String?
          fullpath = File.join(root, filepath)
          File.exists?(fullpath) ? fullpath : nil
        end

        def list : Array(String)
          Dir.glob(File.join(root, "/**/*")).reject { |fn| File.directory?(fn) }
        end
      end
    end
  end
end
