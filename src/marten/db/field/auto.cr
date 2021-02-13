module Marten
  module DB
    module Field
      class Auto < Int
        include IsAutoField

        def from_db_result_set(result_set : ::DB::ResultSet) : Int32 | Int64 | Nil
          # Note: Int64 values are explicitly allowed here (even though they are possibly stored as Int32 at the DB
          # level) because some databases always persist integers as Int64 values.
          result_set.read(Int32 | Int64 | Nil)
        end

        def to_column : Management::Column::Base
          Management::Column::Auto.new(
            db_column,
            primary_key?,
            null?,
            unique?,
            db_index?,
            to_db(default)
          )
        end
      end
    end
  end
end
