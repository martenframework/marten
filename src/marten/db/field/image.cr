require "./file"

module Marten
  module DB
    module Field
      # Represents an image field.
      class Image < File
        def validate(record, value)
          super

          return unless value.is_a?(Marten::DB::Field::File::File)
          return if !value.attached?

          if !value.committed?
            value.open.tap do |io|
              if !Core::Validator::Image.valid?(io)
                record.errors.add(id, I18n.t("marten.db.field.image.errors.not_an_image"))
              end
            end
          end
        end

        macro check_definition(field_id, kwargs)
          {% if !@top_level.has_constant?("Vips") %}
            {% raise "crystal-vips is required when defining `image` model fields." %}
          {% end %}
        end
      end
    end
  end
end
