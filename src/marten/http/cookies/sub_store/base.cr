module Marten
  module HTTP
    class Cookies
      module SubStore
        # Abstract sub cookie store.
        abstract class Base
          def initialize(@store : Cookies)
          end

          def [](name : String | Symbol)
            fetch(name.to_s) { raise KeyError.new(name.to_s) }
          end

          def []?(name : String | Symbol)
            fetch(name) { nil }
          end

          def []=(name, value)
            set(name, value)
          end

          abstract def fetch(name : String | Symbol)
          abstract def fetch(name : String | Symbol, default = nil)
          abstract def set(name : String | Symbol, value, **kwargs) : Nil

          private getter store
        end
      end
    end
  end
end
