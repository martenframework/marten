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
    end
  end
end
