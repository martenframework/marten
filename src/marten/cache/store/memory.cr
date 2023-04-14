module Marten
  module Cache
    module Store
      # A cache store implementation that stores data in memory.
      #
      # `Marten::Cache::Store::Memory` is a cache implementation that stores all data in memory within the same process,
      # making it a fast and reliable option for caching in single process environments. However, it's worth noting that
      # if you're running multiple instances of your application, the cache data will not be shared between them.
      #
      # By default, `Marten::Cache::Store::Memory` does not compress data because it doesn't transmit data over the
      # network. However, compression can be enabled if desired.
      class Memory < Base
        @data = {} of String => String

        def initialize(
          @namespace : String? = nil,
          @expires_in : Time::Span? = nil,
          @version : Int32? = nil,
          @compress = false,
          @compress_threshold = DEFAULT_COMPRESS_THRESHOLD
        )
          super
        end

        def clear : Nil
          @data.clear
        end

        private getter data

        private def delete_entry(key : String) : Bool
          deleted_entry = @data.delete(key)
          !!deleted_entry
        end

        private def read_entry(key : String) : Entry?
          deserialize_entry(data[key]?)
        end

        private def write_entry(
          key : String,
          entry : Entry,
          expires_in : Time::Span? = nil,
          compress : Bool? = nil,
          compress_threshold : Int32? = nil
        )
          serialized_entry = serialize_entry(entry, compress, compress_threshold)

          data[key] = serialized_entry
          true
        end
      end
    end
  end
end
