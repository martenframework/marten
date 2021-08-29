module Marten
  module Asset
    # Represents an assets engine.
    #
    # An assets engine holds a storage to collect, persist and resolve asset URLs, as well as finders to discover the
    # assets to collect.
    class Engine
      @finders = [] of Finder::Base

      getter finders
      getter storage

      setter finders

      def initialize(@storage : Core::Storage::Base)
      end

      # Returns the absolute path corresponding to the passed asset file path.
      def find(filepath : String) : String
        finders.each do |finder|
          return finder.find(filepath)
        rescue Errors::AssetNotFound
        end

        raise Errors::AssetNotFound.new("Asset #{filepath} could not be found")
      end
    end
  end
end
