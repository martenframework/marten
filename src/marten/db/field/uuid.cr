module Marten
  module DB
    module Field
      class UUID < Base
        def from_db_result_set(result_set : ::DB::ResultSet) : ::UUID?
          value = result_set.read(::String?)
          ::UUID.new(value) unless value.nil?
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when ::UUID
            value.to_s
          end
        end
      end
    end
  end
end
