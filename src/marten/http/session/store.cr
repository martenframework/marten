require "./store/**"

module Marten
  module HTTP
    module Session
      module Store
        @@registry = {} of ::String => Base.class

        # Returns the session store class associated with a specific `store_name`.
        #
        # If no session store implementatiob can be found, a `Marten::HTTP::Session::Errors::UnknownStore` exception is
        # raised.
        def self.get(store_name : String | Symbol)
          registry[store_name.to_s]
        rescue KeyError
          raise Errors::UnknownStore.new("Unknown session store '#{store_name}'")
        end

        # Returns the current registry of session stores.
        def self.registry
          @@registry
        end

        # Allows to register a new session store implementation.
        def self.register(name : String | Symbol, klass : Base.class)
          @@registry[name.to_s] = klass
        end

        register "cookie", Cookie
      end
    end
  end
end
