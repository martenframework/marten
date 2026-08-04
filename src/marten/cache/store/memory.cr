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
      #
      # This store is thread-safe: accesses to the underlying in-memory hash are synchronized.
      class Memory < Base
        @data = {} of String => String
        @mutex = Mutex.new

        def initialize(
          @namespace : String? = nil,
          @expires_in : Time::Span? = nil,
          @version : Int32? = nil,
          @compress = false,
          @compress_threshold = DEFAULT_COMPRESS_THRESHOLD,
        )
          super
        end

        def clear : Nil
          @mutex.synchronize { @data.clear }
        end

        def decrement(
          key : String,
          amount : Int32 = 1,
          expires_at : Time? = nil,
          expires_in : Time::Span? = nil,
          version : Int32? = nil,
          race_condition_ttl : Time::Span? = nil,
          compress : Bool? = nil,
          compress_threshold : Int32? = nil,
        ) : Int
          apply_increment(
            key,
            amount: -amount,
            expires_at: expires_at,
            expires_in: expires_in,
            version: version,
            race_condition_ttl: race_condition_ttl,
            compress: compress,
            compress_threshold: compress_threshold
          )
        end

        def delete_entry(key : String) : Bool
          @mutex.synchronize do
            deleted_entry = @data.delete(key)
            !!deleted_entry
          end
        end

        def increment(
          key : String,
          amount : Int32 = 1,
          expires_at : Time? = nil,
          expires_in : Time::Span? = nil,
          version : Int32? = nil,
          race_condition_ttl : Time::Span? = nil,
          compress : Bool? = nil,
          compress_threshold : Int32? = nil,
        ) : Int
          apply_increment(
            key,
            amount: amount,
            expires_at: expires_at,
            expires_in: expires_in,
            version: version,
            race_condition_ttl: race_condition_ttl,
            compress: compress,
            compress_threshold: compress_threshold
          )
        end

        def read_entry(key : String) : String?
          @mutex.synchronize { @data[key]? }
        end

        def write_entry(
          key : String,
          value : String,
          expires_in : Time::Span? = nil,
          race_condition_ttl : Time::Span? = nil,
        )
          @mutex.synchronize do
            @data[key] = value
            true
          end
        end

        private def apply_increment(
          key : String,
          amount : Int32 = 1,
          expires_at : Time? = nil,
          expires_in : Time::Span? = nil,
          version : Int32? = nil,
          race_condition_ttl : Time::Span? = nil,
          compress : Bool? = nil,
          compress_threshold : Int32? = nil,
        )
          normalized_key = normalize_key(key.to_s)

          # Keep the full read-modify-write under one lock, accessing `@data` directly so we don't
          # re-enter the non-reentrant mutex via `#read_entry` / `#write_entry`.
          @mutex.synchronize do
            entry = deserialize_entry(@data[normalized_key]?)

            if entry.nil? || entry.expired? || entry.mismatched?(version || self.version)
              effective_expires_in = if !expires_at.nil?
                                       expires_at.to_utc - Time.utc
                                     else
                                       expires_in.nil? ? self.expires_in : expires_in
                                     end

              @data[normalized_key] = serialize_entry(
                Entry.new(amount.to_s, expires_in: effective_expires_in, version: version || self.version),
                compress,
                compress_threshold
              )
              amount
            else
              new_amount = entry.value.to_i + amount
              entry = Entry.new(new_amount.to_s, expires_at: entry.expires_at, version: entry.version)
              @data[normalized_key] = serialize_entry(entry)
              new_amount
            end
          end
        end
      end
    end
  end
end
