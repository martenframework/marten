require "./string"

module Marten
  module DB
    module Field
      # Represents a slug field.
      class Slug < String
        include Core::Sluggable

        def initialize(
          @id : ::String,
          @max_size : ::Int32 = 50,
          @primary_key = false,
          @default : ::String? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = true,
          @db_column = nil,
          @slugify : Symbol? = nil
        )
        end

        macro check_definition(field_id, kwargs)
          # No-op max_size automatic checks...
        end

        def prepare_save(record, new_record = false)
          if slugify?(record.get_field_value(id))
            slug = generate_slug(record.get_field_value(slugify.not_nil!).to_s, max_size)
            record.set_field_value(id, slug)
          end
        end

        def validate(record, value)
          return if !value.is_a?(::String)

          # Leverage string's built-in validations (max size).
          super

          if !value.empty? && !Core::Validator::Slug.valid?(value)
            record.errors.add(id, I18n.t("marten.db.field.slug.errors.invalid"))
          end
        end

        protected def validate_presence(record : Model, value)
          super if slugify.nil?
        end

        private getter slugify

        private def slugify?(value)
          slugify && empty_value?(value)
        end
      end
    end
  end
end
