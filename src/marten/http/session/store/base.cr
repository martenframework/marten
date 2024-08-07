module Marten
  module HTTP
    module Session
      module Store
        # Abstract base session store.
        abstract class Base
          alias SessionHash = Hash(String, String)

          @accessed : Bool = false
          @expires_at_browser_close : Bool = false
          @expires_in : Time::Span? = nil
          @modified : Bool = false
          @session_hash : SessionHash? = nil

          getter session_key

          getter? expires_at_browser_close

          def initialize(@session_key : String?)
          end

          # Returns the value associated with the passed key or raises a `KeyError` exception if not found.
          def [](key : String | Symbol)
            session_hash[key.to_s]
          end

          # Returns the value associated with the passed key or returns `nil` if not found.
          def []?(key : String | Symbol)
            session_hash[key.to_s]?
          end

          # Allows to set a new session value for a specific `key`.
          def []=(key : String | Symbol, value : String)
            session_hash[key.to_s] = value
            @modified = true
            value
          end

          # Returns `true` if the session store was accessed at least once.
          def accessed? : Bool
            @accessed
          end

          # Regenerates the session key while keeping all the existing data.
          def cycle_key : Nil
            data = session_hash.dup

            flush
            create

            @session_hash = data
          end

          # Allows to delete a session value for a specific `key`.
          def delete(key : String | Symbol)
            deleted_value = session_hash.delete(key.to_s)
            @modified = true
            deleted_value
          end

          # Returns `true` if the session store is empty.
          def empty? : Bool
            session_key.nil? && session_hash.empty?
          end

          # Returns the time when the session will expire.
          #
          # This method will return `nil` if the session is set to expire when the browser is closed.
          def expires_at
            return nil if expires_at_browser_close?

            Time.local + expires_in
          end

          # Allows to set the date time when the session will expire.
          def expires_at=(value : Time)
            @modified = true
            @expires_in = value - Time.local
          end

          # Allows to set whether the session should expire when the browser is closed.
          def expires_at_browser_close=(value : Bool)
            @modified = true
            @expires_at_browser_close = value
          end

          # Returns the session expiration time.
          #
          # Unless explicitly set, the default value returned is the one defined by the `sessions.cookie_max_age`
          # setting.
          def expires_in
            @expires_in ||= Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age)
          end

          # Allows to set the session expiration time.
          def expires_in=(value : Time::Span)
            @modified = true
            @expires_in = value
          end

          # Allows to set the session expiration time in seconds.
          def expires_in=(value : Int64)
            @modified = true
            @expires_in = Time::Span.new(seconds: value)
          end

          # Returns the value associated with the passed `key`, or the passed `default` if the key is not found.
          def fetch(key : String | Symbol, default = nil)
            fetch(key) { default }
          end

          # Returns the value associated with the passed `key`, or calls a block with the key when not found.
          def fetch(key : String | Symbol, &)
            self[key.to_s]? || yield key
          end

          # Returns `true` if the provided `key` exists.
          def has_key?(key : String | Symbol)
            session_hash.has_key?(key.to_s)
          end

          # Returns `true` if the session store was modified.
          def modified? : Bool
            @modified
          end

          delegate each, to: session_hash

          # Returns the number of keys in the session hash.
          delegate size, to: session_hash

          # Creates a new session store.
          #
          # This method should create a new (empty) session store with an associated key and persist it.
          abstract def create : Nil

          # Flushes the session store data.
          abstract def flush : Nil

          # Loads the session store data and returns the corresponding hash.
          abstract def load : SessionHash

          # Saves the session store data.
          abstract def save : Nil

          abstract def clear_expired_entries : Nil

          private def session_hash
            @session_hash ||= begin
              @accessed = true
              load
            end
          end
        end
      end
    end
  end
end
