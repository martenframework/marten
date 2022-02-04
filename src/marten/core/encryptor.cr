module Marten
  module Core
    # Provides the ability to easily encrypt string values.
    #
    # The `Marten::Core::Encryptor` class makes it easy to build encrypted value that are stored in untrusted places. In
    # addition, encrypted values are also signed to prevent tampering.
    #
    # ```
    # encryptor = Marten::Core::Encryptor.new
    # encrypted_value = encryptor.encrypt("hello world") # => "aGVsb..."
    # encryptor.decrypt(encrypted_value)                 # => "hello world"
    # ```
    #
    # `Marten::Core::Encryptor` objects require a `key` that must be at least as long as the cipher key size. By
    # default, an 'aes-256-cbc' cipher is used, which means that keys must be at least 32 characters long. Both the
    # cipher algorithm and the key used to generate encrypted values can be defined at initialization time using the
    # `cipher_algorithm` and the `key` arguments.
    class Encryptor
      class InvalidValueError < Exception; end

      @key : String

      def initialize(key : String? = nil, @cipher_algorithm = "aes-256-cbc")
        @key = key.nil? ? Marten.settings.secret_key : key.not_nil!
        @signer = Signer.new(key: @key)
      end

      # Generates a encrypted ans signed value for the passed `value`.
      #
      # The value is encrypted and signed by using the key used when initializing the encryptor instance:
      #
      # ```
      # encryptor = Marten::Core::Encryptor.new
      # encryptor.encrypt("hello world") # => "aGVsb..."
      # ```
      #
      # It is also possible to define an expiry time for the generated signature by using the `expires` argument:
      #
      # ```
      # encryptor = Marten::Core::Encryptor.new
      # encryptor.encrypt("hello world", expires: Time.local + Time::Span.new(hours: 20)) # => "eyJfb..."
      # ```
      def encrypt(value : String, expires : Time? = nil) : String
        signer.sign(apply_encryption(value), expires: expires)
      end

      # Verifies and decrypt the passed `value` and returns the original value if it is valid, or `nil` otherwise.
      #
      # This method verifies that the signed value has not been tampered, decrypt it, and returns the original value if
      # the signature is valid, and if it is not expired:
      #
      # ```
      # encryptor = Marten::Core::Encryptor.new
      # encrypted_value = encryptor.encrypt("hello world") # => "aGVsb..."
      # encryptor.encrypt(encrypted_value)                 # => "hello world"
      # ```
      #
      # If the passed value is invalid, or if the associated signature is invalid, a `nil` value is returned:
      #
      # ```
      # encryptor = Marten::Core::Encryptor.new
      # encryptor.encrypt("bad_value") # => nil
      # ```
      def decrypt(value : String) : Nil | String
        apply_decryption(signer.unsign!(value))
      rescue ArgumentError | Signer::InvalidSignatureError
        nil
      end

      # Verifies and decrypt the passed `value` and returns the original value if it is valid, or raise an error.
      #
      # This method verifies that the signed value has not been tampered, decrypt it, and returns the original value if
      # the signature is valid, and if it is not expired:
      #
      # ```
      # encryptor = Marten::Core::Encryptor.new
      # encrypted_value = encryptor.encrypt("hello world") # => "aGVsb..."
      # encryptor.encrypt(encrypted_value)                 # => "hello world"
      # ```
      #
      # If the passed value is invalid, or if the associated signature is invalid, a
      # `Marten::Core::Encryptor::InvalidValueError` exception is raised:
      #
      # ```
      # encryptor = Marten::Core::Encryptor.new
      # encryptor.encrypt!("bad_value") # => Marten::Core::Encryptor::InvalidValueError
      # ```
      def decrypt!(value : String) : String
        decrypt(value) || (raise InvalidValueError.new("The provided value cannot be decrypted"))
      end

      private BLOCK_SIZE = 16

      private getter key
      private getter signer

      private def apply_encryption(value)
        cipher = new_cipher
        cipher.encrypt
        cipher.key = key
        iv = cipher.random_iv

        encrypted_data = IO::Memory.new
        encrypted_data.write(cipher.update(value))
        encrypted_data.write(cipher.final)
        encrypted_data.write(iv)

        encrypted_data.rewind
        encrypted_data.to_slice.hexstring
      end

      private def apply_decryption(value)
        cipher = new_cipher

        value = value.hexbytes
        data = value[0, value.size - BLOCK_SIZE]
        iv = value[value.size - BLOCK_SIZE, BLOCK_SIZE]

        cipher.decrypt
        cipher.key = key
        cipher.iv = iv

        decrypted_data = IO::Memory.new
        decrypted_data.write(cipher.update(data))
        decrypted_data.write(cipher.final)

        decrypted_data.rewind
        decrypted_data.gets_to_end
      end

      private def new_cipher
        OpenSSL::Cipher.new(@cipher_algorithm)
      end
    end
  end
end
