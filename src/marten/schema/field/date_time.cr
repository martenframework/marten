module Marten
  abstract class Schema
    module Field
      # Represents a date time schema field.
      class DateTime < Base
        def deserialize(value) : Time?
          return if empty_value?(value)

          date_time = case value
                      when Nil
                        value
                      when ::Time
                        value
                      when ::String
                        parse_date_time(value) || raise_unexpected_field_value(value)
                      when ::JSON::Any
                        deserialize(value.raw)
                      else
                        raise_unexpected_field_value(value)
                      end

          date_time.in(Marten.settings.time_zone) unless date_time.nil?
        end

        def serialize(value) : ::String?
          value.try(&.to_s)
        end

        private def fetch_date_time_format(index)
          I18n.t!("marten.schema.field.date_time.input_formats.#{index}")
        rescue I18n::Errors::MissingTranslation
          nil
        end

        private def invalid_error_message(_schema)
          I18n.t("marten.schema.field.date_time.errors.invalid")
        end

        private def parse_date_time(value)
          result = begin
            Time.parse_iso8601(value)
          rescue Time::Format::Error
            nil
          end

          return result unless result.nil?

          attempt = 0
          format = I18n.t("marten.schema.field.date_time.input_formats.#{attempt}")

          while result.nil? && (format = fetch_date_time_format(attempt))
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
