module Marten
  module Cache
    module Store
      # A cache store implementation that doesn't store any data.
      #
      # `Marten::Cache::Store::Null` is a cache implementation that does not actually cache any data, but provides a way
      # to go through the caching interface. This can be useful in development and testing environments when caching is
      # not desired.
      class Null < Base
        def clear
        end

        private def delete_entry(key : String) : Bool
          false
        end

        private def read_entry(key : String) : Entry?
        end

        private def write_entry(
          key : String,
          entry : Entry,
          expires_in : Time::Span? = nil,
          compress : Bool? = nil,
          compress_threshold : Int32? = nil
        )
          true
        end
      end
    end
  end
end
