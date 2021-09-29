module Marten
  module Asset
    # Represents an assets engine.
    #
    # An assets engine holds a storage to collect, persist and resolve asset URLs, as well as finders to discover the
    # assets to collect.
    class Engine
      @finders = [] of Finder::Base
      @loaded_manifests : Hash(String, String) | Nil = nil
      @manifests = [] of String

      getter finders
      getter manifests
      getter storage

      setter finders
      setter manifests

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

      # Returns the URL associated with the passed file name or file path.
      #
      # If manifests are configured, those will be used in order to try to map the passed `filepath` to a real file path
      # that is fingerprinted. The passed `filepath` will be used as is if it is not present in the configured manifests
      # (or if there are no configured manifests at all).
      def url(filepath : String) : String
        storage.url(loaded_manifests.fetch(filepath, filepath))
      end

      private def loaded_manifests
        @loaded_manifests ||= begin
          h = {} of String => String

          manifests.each do |path|
            h.merge!(Hash(String, String).from_json(File.read(path)))
          end

          h
        end
      end
    end
  end
end
