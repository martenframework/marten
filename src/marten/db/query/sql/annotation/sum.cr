module Marten
  module DB
    module Query
      module SQL
        module Annotation
          class Sum < Base
            def from_db_result_set(result_set : ::DB::ResultSet)
              result_set.read(Int64 | Int32 | Int16 | Int8 | Float64 | Float32 | Nil)
            end

            def to_sql : String
              if distinct?
                "SUM(DISTINCT #{alias_prefix}.#{field.db_column}) as #{alias_name}"
              else
                "SUM(#{alias_prefix}.#{field.db_column}) as #{alias_name}"
              end
            end
          end
        end
      end
    end
  end
end
