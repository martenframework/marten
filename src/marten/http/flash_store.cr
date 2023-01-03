module Marten
  module HTTP
    # Represents a flash messages store.
    #
    # This store provides a way to pass basic string messages from one handler to another. Any string value that is set
    # in this store will be available to the next handler processing the next request, and then it will be cleared out.
    class FlashStore
      include Enumerable({String, String})

      @flashes = {} of String => String
      @discard = [] of String

      # Allows to initialize a flash store from a session store.
      #
      # Flash session values that were previously set (likely by the flash middleware) will be used to populate the new
      # flash store.
      def self.from_session(session : Session::Store::Base)
        flashes = {} of String => String

        session[SESSION_KEY]?.try do |raw_flash_data|
          flash_data = JSON.parse(raw_flash_data).as_h

          flash_data["flashes"].as_h.each { |key, value| flashes[key] = value.to_s }
          flash_data["discard"].as_a?.try { |discarded| flashes.reject!(discarded.map(&.as_s)) }
        end

        new(flashes, flashes.keys)
      end

      def initialize(@flashes = {} of String => String, @discard = [] of String)
      end

      # Returns the message for the passed `key`, or raises a `KeyError` exception if not found.
      def [](key : String | Symbol)
        @flashes[key.to_s]
      end

      # Returns the message for the passed `key`, or `nil` if not found.
      def []?(key : String | Symbol)
        @flashes[key.to_s]?
      end

      # Allows to set a flash message for a given `key`.
      def []=(key : String | Symbol, value : String)
        key = key.to_s
        @discard.delete(key)
        @flashes[key] = value
      end

      # Clears the flash store and returns it.
      def clear
        @discard.clear
        @flashes.clear
        self
      end

      # Deletes the message for the passed `key` and returns its value, otherwise returns `nil`.
      def delete(key : String | Symbol)
        delete(key) { nil }
      end

      # Deletes the message for the passed `key` and returns its value, or calls a block with the key when not found.
      def delete(key : String | Symbol, &block)
        key = key.to_s
        @discard.delete(key)
        @flashes.delete(key, &block)
      end

      # Discards all the flash messages or either one specific flash message key by the end of the current request.
      def discard(key : Nil | String | Symbol = nil)
        key = key.to_s if !key.nil?
        @discard.concat(key.try { |k| [k.to_s] } || @flashes.keys.dup)
        key.nil? ? self : self[key]
      end

      # Returns the message for the passed `key`, or the passed `default` if not found.
      def fetch(key : String | Symbol, default)
        @flashes.fetch(key.to_s, default)
      end

      # Returns the message for the passed `key`, or calls a block with the key when not found.
      def fetch(key : String | Symbol, &)
        self[key]? || yield key
      end

      # Returns `true` if a message associated with the passed `key` exists.
      def has_key?(key : String | Symbol)
        @flashes.has_key?(key.to_s)
      end

      # Keeps all the flash messages or either one specific flash message key for the next request.
      def keep(key : Nil | String | Symbol = nil)
        key = key.to_s if !key.nil?
        @discard -= key.try { |k| [k] } || @flashes.keys
        key.nil? ? self : self[key]
      end

      # Persists the content of the current flash store into the passed session store.
      def persist(session : Session::Store::Base) : Nil
        if (session_value = to_session_value).nil?
          session.delete(SESSION_KEY)
        else
          session[SESSION_KEY] = session_value
        end
      end

      # Iterates over all the flash messages in the current store.
      delegate each, to: @flashes

      # Returns `true` if the flash store is empty.
      delegate empty?, to: @flashes

      # Returns the size of the flash store.
      delegate size, to: @flashes

      private SESSION_KEY = "_flash"

      private def to_session_value
        flashes_to_keep = @flashes.reject(@discard)
        return if flashes_to_keep.empty?

        {"discard" => [] of String, "flashes" => flashes_to_keep}.to_json
      end
    end
  end
end
