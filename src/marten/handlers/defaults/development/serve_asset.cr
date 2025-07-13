module Marten
  module Handlers
    module Defaults
      module Development
        class ServeAsset < Base
          def get
            begin
              filepath = URI.decode(params["path"].as(String))
              asset_fullpath = Marten.assets.find(filepath)
            rescue Asset::Errors::AssetNotFound
              return head 404
            end

            return head 404 if Dir.exists?(asset_fullpath)

            content_type = begin
              MIME.from_filename(asset_fullpath)
            rescue KeyError
              "application/octet-stream"
            end

            respond content: File.read(asset_fullpath), content_type: content_type
          end
        end
      end
    end
  end
end
