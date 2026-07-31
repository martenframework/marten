module Marten
  module DB
    module Field
      class Date < Base
        getter auto_now
        getter auto_now_add
        getter default

        def initialize(
          @id : ::String,
          @primary_key = false,
          @default : Time? = nil,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil,
          @auto_now = false,
          @auto_now_add = false,
        )
          if @auto_now || @auto_now_add
            @blank = true
          end
        end

        # Returns a boolean indicating if the field automatically sets the current time at record save time.
        def auto_now?
          @auto_now
        end

        # Returns a boolean indicating if the field automatically sets the current time at record creation time.
        def auto_now_add?
          @auto_now_add
        end

        def from_db(value) : Time?
          case value
          when Nil
            value.as?(Nil)
          when Time
            local_date(value)
          when ::String
            local_date(parse_db_date_string(value))
          else
            raise_unexpected_field_value(value)
          end
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Time?
          from_db(result_set.read)
        end

        # :nodoc:
        def perform_validation(record : Model)
          return if auto_now? || auto_now_add?
          super
        end

        def prepare_save(record, new_record = false)
          if @auto_now || (@auto_now_add && new_record)
            record.set_field_value(id, local_date(Time.local(Marten.settings.time_zone)))
          end
        end

        def to_column : Management::Column::Base?
          Management::Column::Date.new(
            db_column!,
            primary_key?,
            null?,
            unique?,
            index?,
            to_db(default)
          )
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when Time
            Time.utc(value.year, value.month, value.day)
          else
            raise_unexpected_field_value(value)
          end
        end

        # Returns the start of the calendar date of `value` in the project time zone, or of the next day if that date does
        # not exist there.
        private def local_date(value : Time) : Time
          time = Time.local(value.year, value.month, value.day, location: Marten.settings.time_zone)
          while {time.year, time.month, time.day} < {value.year, value.month, value.day}
            time += 1.hour
          end
          time
        end

        private def parse_db_date_string(value : ::String) : Time
          if value.matches?(/\A\d{4}-\d{2}-\d{2}\z/)
            Time.parse_utc(value, "%F")
          elsif value.includes?(".")
            Time.parse_utc(value, "%F %H:%M:%S.%L")
          else
            Time.parse_utc(value, "%F %H:%M:%S")
          end
        end
      end
    end
  end
end
