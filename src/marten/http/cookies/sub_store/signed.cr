module Marten
  module HTTP
    class Cookies
      module SubStore
        # Signed sub cookie store.
        class Signed < Base
          @signer : Core::Signer? = nil

          # Returns the value matching the passed signed cookie name, or calls a block with the name when not found.
          def fetch(name : String | Symbol, &)
            signer.unsign(store[name])
          rescue KeyError
            yield name
          end

          # Returns the value matchine the passed signed cookie name, or the `default` one if the cookie is not present.
          def fetch(name : String | Symbol, default = nil)
            fetch(name) { default }
          end

          # Allows to set a cookie that is signed to prevent tampering.
          #
          # The string representation of the passed `value` object will be signed, and the resulting string will be used
          # as the cookie value. Appart from the cookie name and value, this method allows to define some additional
          # cookie properties:
          #
          #   * the cookie expiry datetime (`expires` argument)
          #   * the cookie `path`
          #   * the associated `domain` (useful in order to define cross-domain cookies)
          #   * whether or not the cookie should be sent for HTTPS requests only (`secure` argument)
          #   * whether or not client-side scripts should have access to the cookie (`http_only` argument)
          #   * the `same_site` policy (accepted values are `"lax"` or `"strict"`)
          def set(name : String | Symbol, value, **kwargs) : Nil
            store.set(name, signer.sign(value.to_s), **kwargs)
          end

          private def signer
            @signer ||= Core::Signer.new
          end
        end
      end
    end
  end
end
