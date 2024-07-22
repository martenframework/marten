require "./string"

module Marten
  module DB
    module Field
      # Represents a slug field.
      class Slug < String
        NON_ALPHANUMERIC_RE  = /[^\w\s-]/
        WHITESPACE_HYPHEN_RE = /[-\s]+/

        private getter slugify
        private getter slugify_cb

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
          @slugify : Symbol? = nil,
          @slugify_cb : (::String -> ::String) = ->(value : ::String) { generate_slug(value) }
        )
          if @slugify
            @null = true
            @blank = true
          end
        end

        macro check_definition(field_id, kwargs)
          # No-op max_size automatic checks...
        end

        def validate(record, value)
          if slugify?(value)
            slug = slugify_cb.call(record.get_field_value(slugify.not_nil!).to_s)
            record.set_field_value(id, slug)
            return
          end

          return if !value.is_a?(::String)

          # Leverage string's built-in validations (max size).
          super

          if !value.empty? && !Core::Validator::Slug.valid?(value)
            record.errors.add(id, I18n.t("marten.db.field.slug.errors.invalid"))
          end
        end

        private def generate_slug(value)
          suffix = "-#{Random::Secure.hex(4)}"

          slug = value.gsub(NON_ALPHANUMERIC_RE, "").downcase
          slug = slug.gsub(WHITESPACE_HYPHEN_RE, "-").strip("-_")
          slug = slug.unicode_normalize(:nfkc)
          slug = ::String.new(slug.encode("ascii", :skip))

          slug[...(max_size - suffix.size)] + suffix
        end

        private def slugify?(value)
          slugify && (value.nil? || (value.is_a?(::String) && value.blank?))
        end
      end
    end
  end
end
