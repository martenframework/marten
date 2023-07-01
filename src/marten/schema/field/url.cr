require "./string"

module Marten
  abstract class Schema
    module Field
      # Represents a URL schema field.
      class URL < String
        def initialize(
          @id : ::String,
          @required : ::Bool = true,
          @max_size : ::Int32? = 200,
          @min_size : ::Int32? = nil,
          @strip : ::Bool = true
        )
        end

        def validate(schema, value)
          return if !value.is_a?(::String)

          # Leverage string's built-in validations (max size).
          super

          if !value.empty? && !Emailing::Address.valid?(value)
            schema.errors.add(id, I18n.t("marten.schema.field.url.errors.invalid"))
          end
        end
      end
    end
  end
end
