require "./string"

module Marten
  module DB
    module Field
      # Represents an email field.
      class Email < String
        def initialize(
          @id : ::String,
          @max_size : ::Int32 = 254, # Compliant with RFCs 3696 and 5321
          @primary_key = false,
          @default : ::String? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil
        )
        end

        def validate(record, value)
          return if !value.is_a?(::String)

          # Leverage string's built-in validations (max size).
          super

          if !value.empty? && !Emailing::Address.valid?(value)
            record.errors.add(id, I18n.t("marten.db.field.email.errors.invalid"))
          end
        end

        macro check_definition(field_id, kwargs)
          # No-op max_size automatic checks...
        end
      end
    end
  end
end
