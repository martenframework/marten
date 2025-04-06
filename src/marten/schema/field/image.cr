require "./file"

module Marten
  abstract class Schema
    module Field
      # Represents an image schema field.
      class Image < File
        def initialize(
          @id : ::String,
          @required : ::Bool = true,
          @max_name_size : ::Int32? = nil,
        )
          super(id, required, max_name_size, allow_empty_files: false)
        end

        def validate(schema, value)
          super

          return if !value.is_a?(HTTP::UploadedFile)

          if !Core::Validator::Image.valid?(value.io)
            schema.errors.add(id, I18n.t("marten.schema.field.image.errors.not_an_image"))
          end
        end

        macro check_definition(field_id, kwargs)
          {% if !@top_level.has_constant?("Vips") %}
            {% raise "crystal-vips is required when defining `image` schema fields." %}
          {% end %}
        end
      end
    end
  end
end
