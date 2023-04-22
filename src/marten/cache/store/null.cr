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
          0
        end

        def delete_entry(key : String) : Bool
          false
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
          0
        end

        def read_entry(key : String) : String?
        end

        def write_entry(
          key : String,
          value : String,
          expires_in : Time::Span? = nil,
          race_condition_ttl : Time::Span? = nil
        )
          true
        end
      end
    end
  end
end
