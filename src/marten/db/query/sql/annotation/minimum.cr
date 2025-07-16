module Marten
  module DB
    module Query
      module SQL
        module Annotation
          class Minimum < Base
            def from_db_result_set(result_set : ::DB::ResultSet)
              result_set.read(Int64 | Int32 | Int16 | Int8 | Float64 | Float32 | Nil)
            end

            def to_sql(with_alias : Bool = true) : String
              sql_part = if distinct?
                           "MIN(DISTINCT #{alias_prefix}.#{field.db_column})"
                         else
                           "MIN(#{alias_prefix}.#{field.db_column})"
                         end

              with_alias ? "#{sql_part} as #{alias_name}" : sql_part
            end
          end
        end
      end
    end
  end
end
