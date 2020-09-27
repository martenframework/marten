module Marten
  module DB
    module Field
      class BigAuto < BigInt
        include IsAutoField

        def to_column : Migration::Column::Base
          Migration::Column::BigAuto.new(
            db_column,
            primary_key?,
            null?,
            unique?,
            db_index?
          )
        end
      end
    end
  end
end
