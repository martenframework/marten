module Marten
  module Conf
    class GlobalSettings
      # Allows to configure assets-related settings.
      class Assets
        @app_dirs : Bool = true
        @dirs : Array(String) = [] of String
        @manifests : Array(String) = [] of String
        @root : String = "assets"
        @storage : Core::Storage::Base? = nil
        @url : String = "/assets/"

        # Returns a boolean indicating whether assets should be looked for inside installed applications.
        getter app_dirs

        # Returns an array of directories where assets should be looked for.
        #
        # The order of these directories is important as it defines the order in which assets are searched for.
        getter dirs

        # Returns the configured paths to manifest JSON files to use to resolve assets URLs.
        getter manifests

        # Returns the absolute path where collected assets will be persisted.
        getter root

        # Returns the storage used to collect and persist assets.
        getter storage

        # Returns the base URL to use when exposing asset URLs.
        getter url

        # Allows to set whether assets should be looked for inside installed applications.
        setter app_dirs

        # Allows to set the base URL to use when exposing asset URLs.
        setter url

        # Allows to set the directories where assets should be looked for.
        def dirs=(dirs : Array(Path | String | Symbol))
          @dirs = dirs.map do |dir|
            case dir
            when Path
              dir.expand.to_s
            else
              dir.to_s
            end
          end
        end

        # Allows to set paths to manifest JSON files to use in order to resolve asset URLs.
        def manifests=(manifests : Array(Path | String | Symbol))
          @manifests = manifests.map do |path|
            case path
            when Path
              path.expand.to_s
            else
              path.to_s
            end
          end
        end

        # Allows to set the absolute path where collected assets will be persisted.
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

        # Allows to set the the storage used to collect and persist assets.
        def storage=(storage : Core::Storage::Base | Nil)
          @storage = storage
        end
      end
    end
  end
end
