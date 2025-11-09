module Marten
  module HTTP
    # Represents an uploaded file.
    class UploadedFile
      @io : ::File

      # Returns the `File` object associated with the corresponding temporary file.
      getter io

      def initialize(@part : ::HTTP::FormData::Part, @ct : String = "text/plain")
        @io = File.tempfile
        ::File.open(@io.as(File).path, "w") do |file|
          IO.copy(@part.body, file)
        end
      end

      def to_json
        JSON.build { |json| to_json(json) }
      end

      def to_json(json : JSON::Builder)
        json.object do
          json.field "original_filename", @part.filename
          json.field "tempfile", @io.inspect
          json.field "content_type", @ct
        end
      end

      # Returns the uploaded file name.
      delegate filename, to: @part

      # Returns the uploaded file size.
      delegate size, to: @io
    end
  end
end
