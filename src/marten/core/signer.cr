module Marten
  module Core
    # Provides the ability to easily sign string values to prevent tampering.
    #
    # The `Marten::Core::Signer` class makes it easy to build signed value, and to verify that they have not been
    # tampered:
    #
    # ```
    # signer = Marten::Core::Signer.new
    # signed_value = signer.sign("hello world") # => "aGVsb..."
    # signer.unsign(signed_value)               # => "hello world"
    # ```
    #
    # `Marten::Core::Signer` objects create HMAC signatures using the SHA256 hash algorithm by default. They also use
    # Marten's configured secret key by default. Both the algorithm and the key used to generate signatures can be
    # defined at initialization time using the `algorithm` and the `key` arguments:
    #
    # ```
    # signer = Marten::Core::Signer.new(key: "insecure_key", algorithm: OpenSSL::Algorithm::SHA1)
    # ```
    class Signer
      class InvalidSignatureError < Exception; end

      @key : String

      def initialize(key : String? = nil, @algorithm : OpenSSL::Algorithm = OpenSSL::Algorithm::SHA256)
        @key = key.nil? ? Marten.settings.secret_key : key.not_nil!
      end

      # Generates a signed value for the passed `value`.
      #
      # The value is signed by using the key used when initializing the signer instance. A Base64-encoded version of the
      # original data is embedded in the generated signature:
      #
      # ```
      # signer = Marten::Core::Signer.new
      # signer.sign("hello world") # => "aGVsb..."
      # ```
      #
      # It is also possible to define an expiry time for the generated signature by using the `expires` argument:
      #
      # ```
      # signer = Marten::Core::Signer.new
      # signer.sign("hello world", expires: Time.local + Time::Span.new(hours: 20)) # => "eyJfb..."
      # ```
      def sign(value : String, expires : Time? = nil) : String
        data = if !expires.nil?
                 {
                   "_marten" => {
                     "value"   => encode_data(value),
                     "expires" => Time::Format::RFC_3339.format(expires.to_utc, fraction_digits: 0),
                   },
                 }.to_json
               else
                 value
               end

        data = encode_data(data)

        String.build do |s|
          s << data
          s << SEPARATOR
          s << generate_digest(data)
        end
      end

      # Verifies the signature of the passed `value` and returns the original value if it is valid, or `nil` otherwise.
      #
      # This method verifies that the signed value has not been tampered and returns the original value if the signature
      # is valid, and if it is not expired:
      #
      # ```
      # signer = Marten::Core::Signer.new
      # signed_value = signer.sign("hello world") # => "aGVsb..."
      # signer.unsign(signed_value)               # => "hello world"
      # ```
      #
      # If the passed value is invalid, or if the associated signature is invalid, a `nil` value is returned:
      #
      # ```
      # signer = Marten::Core::Signer.new
      # signer.unsign("bad_value") # => nil
      # ```
      def unsign(value : String) : Nil | String
        return unless valid_signature?(value)

        data = decode_data(value.split(SEPARATOR).first)

        parsed_data = begin
          JSON.parse(data)
        rescue JSON::ParseException
          nil
        end

        if !parsed_data.nil? && parsed_data.as_h? && (parsed_data_hash = parsed_data.as_h).has_key?("_marten")
          # At this point it is assumed that the parsed hash if a reserved "_marten" metadata hash.
          embedded_value = parsed_data_hash.not_nil!.dig("_marten", "value").as_s
          embedded_expiry = Time.parse_iso8601(parsed_data_hash.not_nil!.dig("_marten", "expires").as_s)

          decode_data(embedded_value) if Time.utc < embedded_expiry
        else
          data
        end
      rescue Base64::Error
        nil
      end

      # Verifies the signature of the passed `value` and returns the original value if it is valid, or raise an error.
      #
      # This method verifies that the signed value has not been tampered and returns the original value if the signature
      # is valid, and if it is not expired:
      #
      # ```
      # signer = Marten::Core::Signer.new
      # signed_value = signer.sign("hello world") # => "aGVsb..."
      # signer.unsign!(signed_value)              # => "hello world"
      # ```
      #
      # If the passed value is invalid, or if the associated signature is invalid, a
      # `Marten::Core::Signer::InvalidSignatureError` exception is raised:
      #
      # ```
      # signer = Marten::Core::Signer.new
      # signer.unsign!("bad_value") # => Marten::Core::Signer::InvalidSignatureError
      # ```
      def unsign!(value : String) : String
        unsign(value) || (raise InvalidSignatureError.new("The provided signature is invalid"))
      end

      private SEPARATOR = "--"

      private getter algorithm
      private getter key

      private def decode_data(data)
        Base64.decode_string(data)
      end

      private def encode_data(data)
        Base64.strict_encode(data)
      end

      private def generate_digest(data)
        OpenSSL::HMAC.hexdigest(algorithm, key, data)
      end

      private def valid_signature?(value)
        return false if !value.valid_encoding? || value.blank?

        data, digest = value.split(SEPARATOR, limit: 2)
        return false if data.blank? || digest.blank?

        Crypto::Subtle.constant_time_compare(digest, generate_digest(data))
      rescue IndexError
        false
      end
    end
  end
end
