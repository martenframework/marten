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
            value.in(Marten.settings.time_zone).as?(Time)
          when ::String
            parse_db_date_string(value).in(Marten.settings.time_zone)
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
            record.set_field_value(id, Time.local.at_beginning_of_day)
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
            value.at_beginning_of_day.to_utc
          else
            raise_unexpected_field_value(value)
          end
        end

        private def parse_db_date_string(value : ::String) : Time
          if value.matches?(/\A\d{4}-\d{2}-\d{2}\z/)
            Time.parse(value, "%F", Marten.settings.time_zone)
          elsif value.includes?(".")
            Time.parse(value, "%F %H:%M:%S.%L", Marten.settings.time_zone).at_beginning_of_day
          else
            Time.parse(value, "%F %H:%M:%S", Marten.settings.time_zone).at_beginning_of_day
          end
        end
      end
    end
  end
end
