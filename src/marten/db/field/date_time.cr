module Marten
  module DB
    module Field
      class DateTime < Base
        def from_db_result_set(result_set : ::DB::ResultSet) : Time?
          value = result_set.read(Time?)
          value.in(Marten.settings.time_zone) unless value.nil?
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when Time
            value.to_utc
          else
            raise Errors::UnexpectedFieldValue.new("Unexpected value received for field '#{id}': #{value}")
          end
        end
      end
    end
  end
end
