module Marten
  module DB
    module SQL
      class Query
        def initialize(@model_klass : Model.class)
        end

        def count
          @model_klass.connection.open do |db|
            result = db.scalar("SELECT COUNT(*) FROM #{table_name_with_quotes}")
            result.to_s.to_i
          end
        end

        private def table_name_with_quotes
          @model_klass.connection.quote(@model_klass.table_name)
        end
      end
    end
  end
end
