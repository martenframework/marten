require "./string"

module Marten
  abstract class Schema
    module Field
      # Represents an email schema field.
      class Email < String
        def initialize(
          @id : ::String,
          @required : ::Bool = true,
          @max_size : ::Int32? = 254, # Compliant with RFCs 3696 and 5321
          @min_size : ::Int32? = nil,
          @strip : ::Bool = true
        )
        end

        def validate(schema, value)
          return if !value.is_a?(::String)

          # Leverage string's built-in validations (max size).
          super

          if !value.empty? && !Emailing::Address.valid?(value)
            schema.errors.add(id, I18n.t("marten.schema.field.email.errors.invalid"))
          end
        end
      end
    end
  end
end
