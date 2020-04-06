module Marten
  module HTTP
    class Data
      # :nodoc:
      alias Value = String | UploadedFile

      # :nodoc:
      alias RawHash = Hash(String, Array(Value))

      def initialize(@params : RawHash)
      end
    end
  end
end
