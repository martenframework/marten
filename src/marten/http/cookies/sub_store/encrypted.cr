module Marten
  module HTTP
    class Cookies
      module SubStore
        # Encrypted sub cookie store.
        class Encrypted < Base
          @encryptor : Core::Encryptor? = nil

          # Returns the value matching the passed encrypted cookie name, or calls a block with the name when not found.
          def fetch(name : String | Symbol, &)
            encryptor.decrypt(store[name])
          rescue KeyError
            yield name
          end

          # Returns the value matchine the passed encrypted cookie name, or the `default` one if it is not present.
          def fetch(name : String | Symbol, default = nil)
            fetch(name) { default }
          end

          # Allows to set a cookie that is encrypted.
          #
          # The string representation of the passed `value` object will be encrypted, and the resulting string will be
          # used as the cookie value. Appart from the cookie name and value, this method allows to define some
          # additional cookie properties:
          #
          #   * the cookie expiry datetime (`expires` argument)
          #   * the cookie `path`
          #   * the associated `domain` (useful in order to define cross-domain cookies)
          #   * whether or not the cookie should be sent for HTTPS requests only (`secure` argument)
          #   * whether or not client-side scripts should have access to the cookie (`http_only` argument)
          #   * the `same_site` policy (accepted values are `"lax"` or `"strict"`)
          def set(name : String | Symbol, value, **kwargs) : Nil
            store.set(name, encryptor.encrypt(value.to_s), **kwargs)
          end

          private def encryptor
            @encryptor ||= Core::Encryptor.new
          end
        end
      end
    end
  end
end
