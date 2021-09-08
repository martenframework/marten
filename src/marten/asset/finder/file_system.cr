module Marten
  module Asset
    module Finder
      # Represents an asset finder allowing to find assets in the local file system, in a given directory.
      class FileSystem < Base
        getter root

        def initialize(@root : String)
        end

        def find(filepath : String) : String
          fullpath = File.join(root, filepath)
          return fullpath if File.exists?(fullpath)
          raise Errors::AssetNotFound.new("Asset #{filepath} could not be found")
        end

        def list : Array({String, String})
          Dir.glob(File.join(root, "/**/*")).reject { |fn| File.directory?(fn) }.map do |path|
            {Path[path].relative_to(root_path).to_s, path}
          end
        end

        private def root_path
          @root_path ||= Path[root]
        end
      end
    end
  end
end
