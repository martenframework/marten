module Marten
  module DB
    module Field
      class DateTime < Base
        def from_db_result_set(result_set : ::DB::ResultSet) : Time?
          value = result_set.read(Time?)
          value.in(Marten.settings.time_zone) unless value.nil?
        end
      end
    end
  end
end
