module Marten
  module DB
    module Field
      class String < Base
        def from_db_result_set(result_set : ::DB::ResultSet) : ::String
          result_set.read(::String)
        end
      end
    end
  end
end
