module Marten
  module Core
    module Storage
      # A basic file system storage that stores files locally.
      class FileSystem < Base
        def initialize(@root : String, @base_url : String)
        end

        def url(filepath : String) : String
          URI.encode(File.join(base_url, filepath))
        end

        private getter root
        private getter base_url
      end
    end
  end
end
