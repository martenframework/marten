require "./string"

module Marten
  abstract class Schema
    module Field
      # Represents an slug schema field.
      class Slug < String
        def initialize(
          @id : ::String,
          @required : ::Bool = true,
          @max_size : ::Int32? = 50,
          @min_size : ::Int32? = nil,
          @strip : ::Bool = true
        )
        end

        def validate(schema, value)
          return if !value.is_a?(::String)

          # Leverage string's built-in validations (max size).
          super

          if !value.empty? && !Core::Validator::Slug.valid?(value)
            schema.errors.add(id, I18n.t("marten.schema.field.slug.errors.invalid"))
          end
        end
      end
    end
  end
end
