module Marten
  module Emailing
    # Represents an email attachment.
    struct Attachment
      @content : Bytes

      # Returns the attached file name.
      getter filename

      # Returns the attachment MIME type.
      getter mime_type

      # Returns the attached content bytes.
      getter content

      def initialize(@filename : String, @mime_type : String, content : Bytes)
        @content = content.dup
      end

      # Returns the attachment size in bytes.
      def size : Int32
        content.size
      end
    end
  end
end
