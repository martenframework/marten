module Marten
  module DB
    module Field
      class DateTime < Base
        def from_db_result_set(result_set : ::DB::ResultSet) : Time
          result_set.read(Time)
        end
      end
    end
  end
end
