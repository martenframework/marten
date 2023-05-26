module Marten
  abstract class Schema
    module Field
      # Represents a file schema field.
      class File < Base
        # Returns the maximum name size allowed.
        getter max_name_size

        def initialize(
          @id : ::String,
          @required : ::Bool = true,
          @max_name_size : ::Int32? = nil,
          @allow_empty_files : ::Bool = false
        )
        end

        # Returns `true` if empty files are allowed.
        def allow_empty_files?
          @allow_empty_files
        end

        def deserialize(value) : HTTP::UploadedFile?
          case value
          when HTTP::UploadedFile
            value
          when Nil
            value
          when ::String
            value.empty? ? nil : raise_unexpected_field_value(value)
          when ::JSON::Any
            deserialize(value.raw)
          else
            raise_unexpected_field_value(value)
          end
        end

        def serialize(value) : ::String?
          # Files cannot really be serialized as strings, so simply return nil.
          nil
        end

        def validate(schema, value)
          return if !value.is_a?(HTTP::UploadedFile)

          if max_name_size && value.filename && value.filename.not_nil!.size > max_name_size.not_nil!
            schema.errors.add(
              id,
              I18n.t("marten.schema.field.file.errors.file_name_too_long", max_name_size: max_name_size)
            )
          end

          if !allow_empty_files? && value.size == 0
            schema.errors.add(id, I18n.t("marten.schema.field.file.errors.empty"))
          end
        end
      end
    end
  end
end
