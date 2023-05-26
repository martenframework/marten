module Marten
  abstract class Schema
    module Field
      # Represents a duration schema field.
      class Duration < Base
        def deserialize(value) : Time::Span?
          return if empty_value?(value)

          case value
          when Nil
            value
          when ::Time::Span
            value
          when ::String
            parse_duration(value) || raise_unexpected_field_value(value)
          when ::JSON::Any
            deserialize(value.raw)
          else
            raise_unexpected_field_value(value)
          end
        end

        def serialize(value) : ::String?
          value.try(&.to_s)
        end

        private DURATION_RE = /
          ^
          (?:(?P<days>-?\d+)\.)?
          ((?:(?P<hours>\d+):)(?=\d+:\d+))?
          (?:(?P<minutes>\d+):)?
          (?P<seconds>\d+)
          (?:[\.,](?P<nanoseconds>\d{1,9})\d{0,9})?
          $
        /xi

        private ISO8601_DURATION_RE = /
          ^(?P<sign>[-+]?)
          P
          (?:(?P<days>\d+([\.,]\d+)?)D)?
          (?:T
          (?:(?P<hours>\d+([\.,]\d+)?)H)?
          (?:(?P<minutes>\d+([\.,]\d+)?)M)?
          (?:(?P<seconds>\d+)(?:[\.,](?P<nanoseconds>\d{1,9})\d{0,9})?S)?
          )?
          $
        /xi

        private def invalid_error_message(_schema) : ::String
          I18n.t("marten.schema.field.duration.errors.invalid")
        end

        private def parse_duration(value : ::String) : ::Time::Span?
          match = value.match(DURATION_RE) || value.match(ISO8601_DURATION_RE)
          return if !match

          sign = match.named_captures.fetch("sign", "+") == "-" ? -1 : 1

          nanoseconds = if match.named_captures["nanoseconds"]?
                          match.named_captures["nanoseconds"].to_s.ljust(9, '0').to_i64
                        else
                          0
                        end

          days = match.named_captures["days"]?.try(&.to_i64) || 0
          hours = match.named_captures["hours"]?.try(&.to_i64) || 0
          minutes = match.named_captures["minutes"]?.try(&.to_i64) || 0
          seconds = match.named_captures["seconds"]?.try(&.to_i64) || 0

          if match.regex == ISO8601_DURATION_RE
            days *= sign
          end

          days_span = Time::Span.new(days: days)
          span = Time::Span.new(hours: hours, minutes: minutes, seconds: seconds, nanoseconds: nanoseconds)

          days_span + span * sign
        end
      end
    end
  end
end
