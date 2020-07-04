module Marten
  module DB
    module Field
      class Integer < Base
        def from_db_result_set(result_set : ::DB::ResultSet) : Int32?
          result_set.read(Int32?)
        end
      end
    end
  end
end
