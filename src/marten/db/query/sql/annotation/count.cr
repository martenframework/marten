module Marten
  module DB
    module Query
      module SQL
        module Annotation
          class Count < Base
            def from_db_result_set(result_set : ::DB::ResultSet)
              result_set.read(Int64 | Int32 | Int16 | Int8 | Nil)
            end

            def to_sql : String
              if distinct?
                "COUNT(DISTINCT #{alias_prefix}.#{field.db_column}) as #{alias_name}"
              else
                "COUNT(#{alias_prefix}.#{field.db_column}) as #{alias_name}"
              end
            end
          end
        end
      end
    end
  end
end
