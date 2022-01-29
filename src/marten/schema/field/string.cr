module Marten
  abstract class Schema
    module Field
      # Represents a string schema field.
      class String < Base
        # Returns the maximum string size allowed.
        getter max_size

        # Returns the minimum string size allowed.
        getter min_size

        def initialize(
          @id : ::String,
          @required : ::Bool = true,
          @max_size : ::Int32? = nil,
          @min_size : ::Int32? = nil,
          @strip : ::Bool = true
        )
        end

        def deserialize(value) : ::String?
          strip? ? value.to_s.strip : value.to_s
        end

        def serialize(value) : ::String?
          value.try(&.to_s)
        end

        # Returns `true` if the string value should be stripped of leading and trailing whitespaces.
        def strip?
          @strip
        end

        def validate(schema, value)
          return if !value.is_a?(::String)

          if !min_size.nil? && value.size < min_size.not_nil!
            schema.errors.add(id, I18n.t("marten.schema.field.string.errors.too_short", min_size: min_size))
          end

          if !max_size.nil? && value.size > max_size.not_nil!
            schema.errors.add(id, I18n.t("marten.schema.field.string.errors.too_long", max_size: max_size))
          end
        end
      end
    end
  end
end
