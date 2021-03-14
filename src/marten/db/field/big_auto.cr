module Marten
  module DB
    module Field
      class BigAuto < BigInt
        include IsAutoField

        def to_column : Management::Column::Base?
          Management::Column::BigAuto.new(
            db_column!,
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
