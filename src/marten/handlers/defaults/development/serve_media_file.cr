module Marten
  module Handlers
    module Defaults
      module Development
        class ServeMediaFile < Base
          def get
            filepath = params["path"].as(String)
            return head 404 if !Marten.media_files_storage.exists?(filepath)

            content_type = begin
              MIME.from_filename(filepath)
            rescue KeyError
              "application/octet-stream"
            end

            file_io = Marten.media_files_storage.open(filepath)
            respond content: file_io.gets_to_end, content_type: content_type
          rescue IO::Error
            head 404
          end
        end
      end
    end
  end
end
