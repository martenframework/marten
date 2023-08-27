module Marten
  module CLI
    abstract class Generator
      # Allows to generate a new secret key value.
      class SecretKey < Generator
        generator_name :secretkey
        help "Generate a new secret key value."

        def run : Nil
          command.print(Random::Secure.base64(32))
        end
      end
    end
  end
end
