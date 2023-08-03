require "./string"

module Marten
  module DB
    module Field
      # Represents an slug field.
      class Slug < String
        def initialize(
          @id : ::String,
          @max_size : ::Int32 = 50,
          @primary_key = false,
          @default : ::String? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = true,
          @db_column = nil
        )
        end

        def validate(record, value)
          return if !value.is_a?(::String)

          # Leverage string's built-in validations (max size).
          super

          if !value.empty? && !Core::Validator::Slug.valid?(value)
            record.errors.add(id, I18n.t("marten.db.field.slug.errors.invalid"))
          end
        end

        macro check_definition(field_id, kwargs)
          # No-op max_size automatic checks...
        end
      end
    end
  end
end
