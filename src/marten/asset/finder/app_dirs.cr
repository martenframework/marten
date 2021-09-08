require "./base"
require "./file_system"

module Marten
  module Asset
    module Finder
      # Represents an asset finder allowing to find assets in the installed application directories.
      class AppDirs < Base
        @app_finders : Array(Finder::Base)

        def initialize
          @app_finders = [] of Finder::Base
          @app_finders += Marten.apps.app_configs.compact_map(&.assets_finder)
        end

        def find(filepath : String) : String
          app_finders.each do |finder|
            return finder.find(filepath)
          rescue Errors::AssetNotFound
          end

          raise Errors::AssetNotFound.new("Asset #{filepath} could not be found")
        end

        def list : Array({String, String})
          app_finders.reduce([] of Tuple(String, String)) { |acc, finder| acc + finder.list }
        end

        private getter app_finders
      end
    end
  end
end
