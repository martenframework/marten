module Marten
  abstract class Schema
    module Field
      # Represents a date schema field.
      class Date < Base
        def deserialize(value) : Time?
          return if empty_value?(value)

          date = case value
                 when Nil
                   value
                 when ::Time
                   value
                 when ::String
                   parse_date(value) || raise_unexpected_field_value(value)
                 when ::JSON::Any
                   deserialize(value.raw)
                 else
                   raise_unexpected_field_value(value)
                 end

          date.in(Marten.settings.time_zone) unless date.nil?
        end

        def serialize(value) : ::String?
          case value
          when ::Time
            value.to_s("%F")
          else
            value.try(&.to_s)
          end
        end

        private def fetch_date_format(index)
          I18n.t!("marten.schema.field.date.input_formats.#{index}")
        rescue I18n::Errors::MissingTranslation
          nil
        end

        private def invalid_error_message(_schema)
          I18n.t("marten.schema.field.date.errors.invalid")
        end

        private def parse_date(value)
          result = nil
          attempt = 0
          format = I18n.t("marten.schema.field.date.input_formats.#{attempt}")

          while result.nil? && (format = fetch_date_format(attempt))
            result = begin
              Time.parse(value, format, Marten.settings.time_zone)
            rescue Time::Format::Error
              nil
            end

            attempt += 1
          end

          result
        end
      end
    end
  end
end
