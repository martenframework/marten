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

        def decrement(
          key : String,
          amount : Int32 = 1,
          expires_at : Time? = nil,
          expires_in : Time::Span? = nil,
          version : Int32? = nil,
          race_condition_ttl : Time::Span? = nil,
          compress : Bool? = nil,
          compress_threshold : Int32? = nil
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
          deleted_entry = @data.delete(key)
          !!deleted_entry
        end

        def increment(
          key : String,
          amount : Int32 = 1,
          expires_at : Time? = nil,
          expires_in : Time::Span? = nil,
          version : Int32? = nil,
          race_condition_ttl : Time::Span? = nil,
          compress : Bool? = nil,
          compress_threshold : Int32? = nil
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
          data[key]?
        end

        def write_entry(
          key : String,
          value : String,
          expires_in : Time::Span? = nil,
          race_condition_ttl : Time::Span? = nil
        )
          data[key] = value
          true
        end

        private getter data

        private def apply_increment(
          key : String,
          amount : Int32 = 1,
          expires_at : Time? = nil,
          expires_in : Time::Span? = nil,
          version : Int32? = nil,
          race_condition_ttl : Time::Span? = nil,
          compress : Bool? = nil,
          compress_threshold : Int32? = nil
        )
          normalized_key = normalize_key(key.to_s)
          entry = deserialize_entry(read_entry(normalized_key))

          if entry.nil? || entry.expired? || entry.mismatched?(version || self.version)
            write(
              key: key,
              value: amount.to_s,
              expires_at: expires_at,
              expires_in: expires_in,
              version: version,
              race_condition_ttl: race_condition_ttl,
              compress: compress,
              compress_threshold: compress_threshold
            )
            amount
          else
            new_amount = entry.value.to_i + amount
            entry = Entry.new(new_amount.to_s, expires_at: entry.expires_at, version: entry.version)
            write_entry(normalized_key, serialize_entry(entry))
            new_amount
          end
        end
      end
    end
  end
end
