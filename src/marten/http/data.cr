module Marten
  module HTTP
    class Data
      alias UploadedFilesHash = Hash(String, Array(UploadedFile))

      def initialize(@params : ::HTTP::Params, @files : UploadedFilesHash)
      end
    end
  end
end
