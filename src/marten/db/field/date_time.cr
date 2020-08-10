module Marten
  module DB
    module Field
      class DateTime < Base
        def initialize(
          @id : ::String,
          @primary_key = false,
          @blank = false,
          @null = false,
          @editable = true,
          @name = nil,
          @auto_now = false,
          @auto_now_add = false
        )
          if @auto_now || @auto_now_add
            @blank = true
            @editable = false
          end
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Time?
          value = result_set.read(Time?)
          value.in(Marten.settings.time_zone) unless value.nil?
        end

        def prepare_save(record, new_record = false)
          if @auto_now || (@auto_now_add && new_record)
            record.set_field_value(id, Time.local)
          end
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when Time
            value.to_utc
          else
            raise_unexpected_field_value(value)
          end
        end
      end
    end
  end
end
