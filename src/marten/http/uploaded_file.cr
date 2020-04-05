module Marten
  module HTTP
    class UploadedFile
      def initialize(@part : ::HTTP::FormData::Part)
      end
    end
  end
end
