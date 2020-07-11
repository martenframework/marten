module Marten
  module DB
    module Field
      class String < Base
        def from_db_result_set(result_set : ::DB::ResultSet) : ::String?
          result_set.read(::String?)
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when ::String
            value
          end
        end
      end
    end
  end
end
