module Marten
  module HTTP
    class Data
      alias Value = String | UploadedFile
      alias RawHash = Hash(String, Array(Value))

      def initialize(@params : RawHash)
      end
    end
  end
end
