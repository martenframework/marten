module Marten
  module Cache
    # Represents a cache entry.
    #
    # Cache entries are associated with a value, an optional version, and an optional expiration timestamp. These
    # entries are serialized using MessagePack before being written to the cache store: when reading from the cache,
    # entries are "reconstructed" by deserializing the corresponding raw MessagePack binary value.
    struct Entry
      # Returns the expiration timestamp for the entry.
      getter expires_at

      # Returns the entry value.
      getter value

      # Returns the entry version.
      getter version

      # Allows to set the expiration timestamp for the entry.
      setter expires_at

      # Unpacks a serialized entry value and returns the corresponding `Entry` object.
      def self.unpack(packed : String)
        unpacked = Tuple(String, Float64?, Int32?).from_msgpack(packed.hexbytes)
        new(value: unpacked[0], expires_at: unpacked[1], version: unpacked[2])
      end

      # Creates a new cache entry for the specified value and options.
      def initialize(
        @value : String,
        @version : Int32? = nil,
        expires_in : Time::Span? = nil
      )
        @expires_at = expires_in ? (expires_in.to_f + Time.utc.to_unix_f) : nil
      end

      # :ditto:
      def initialize(
        @value : String,
        @expires_at : Float64? = nil,
        @version : Int32? = nil
      )
      end

      # Returns `true` if the entry is expired.
      def expired?
        if !(expires_at = @expires_at).nil?
          return expires_at <= Time.utc.to_unix_f
        end

        false
      end

      # Returns `true` if there is a version mismatch between the entry version and the specified version.
      def mismatched?(version : Int32?)
        !version.nil? && !self.version.nil? && version != self.version
      end

      # Packs the entry object and returns the corresponding serialized value.
      def pack : String
        {value, expires_at, version}.to_msgpack.hexstring
      end
    end
  end
end
