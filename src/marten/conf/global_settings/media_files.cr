module Marten
  module Conf
    class GlobalSettings
      # Allows to configure media files-related settings.
      class MediaFiles
        @root : String = "media"
        @storage : Core::Storage::Base? = nil
        @url : String = "/media/"

        # Returns the absolute path where media files will be persisted.
        getter root

        # Returns the ID of the storage used to collect and persist media files.
        getter storage

        # Returns the base URL to use when exposing media file URLs.
        getter url

        # Allows to set the base URL to use when exposing media file URLs.
        setter url

        # Allows to set the absolute path where collected media fiels will be persisted.
        def root=(dir : Path | String | Symbol | Nil)
          @root = case dir
                  when Path
                    dir.expand.to_s
                  when Symbol
                    dir.to_s
                  else
                    dir
                  end
        end

        # Allows to set the the storage used to collect and persist media files.
        def storage=(storage : Core::Storage::Base | Nil)
          @storage = storage
        end
      end
    end
  end
end
