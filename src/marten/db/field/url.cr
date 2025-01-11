require "./string"

module Marten
  module DB
    module Field
      # Represents a URL field.
      class URL < String
        def initialize(
          @id : ::String,
          @max_size : ::Int32 = 200,
          @primary_key = false,
          @default : ::String? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil,
        )
        end

        def validate(record, value)
          return if !value.is_a?(::String)

          # Leverage string's built-in validations (max size).
          super

          if !value.empty? && !Core::Validator::URL.valid?(value)
            record.errors.add(id, I18n.t("marten.db.field.url.errors.invalid"))
          end
        end

        macro check_definition(field_id, kwargs)
          # No-op max_size automatic checks...
        end
      end
    end
  end
end
