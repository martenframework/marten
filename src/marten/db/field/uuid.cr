module Marten
  module DB
    module Field
      class UUID < Base
        def from_db_result_set(result_set : ::DB::ResultSet) : ::UUID
          value = result_set.read(::String)
          ::UUID.new(value)
        end
      end
    end
  end
end
