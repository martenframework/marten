module Marten
  module HTTP
    module Session
      module Store
        # Cookie session store.
        class Cookie < Base
          @encryptor : Core::Encryptor? = nil

          def create : Nil
            @modified = true
          end

          def flush : Nil
            @session_hash = SessionHash.new
            @session_key = nil
            @modified = true
          end

          def load : SessionHash
            SessionHash.from_json(encryptor.decrypt!(@session_key.not_nil!))
          rescue Core::Encryptor::InvalidValueError | NilAssertionError
            create
            SessionHash.new
          end

          def save : Nil
            @modified = true
            @session_key = encryptor.encrypt(session_hash.to_json)
          end

          private def encryptor
            @encryptor ||= Core::Encryptor.new
          end
        end
      end
    end
  end
end
