module Marten
  module Views
    module Defaults
      module Development
        class ServeMediaFile < Base
          def get
            media_file_fullpath = File.join(Marten.settings.media_files.root, params["path"].as(String))
            return head 404 if Dir.exists?(media_file_fullpath)

            content_type = begin
              MIME.from_filename(media_file_fullpath)
            rescue KeyError
              "application/octet-stream"
            end

            respond content: File.read(media_file_fullpath), content_type: content_type
          rescue File::NotFoundError
            head 404
          end
        end
      end
    end
  end
end
