require "./base"

module Marten
  module DB
    module Query
      module SQL
        module Annotation
          class Average < Base
            def from_db_result_set(result_set : ::DB::ResultSet)
              result_set.read(Float64 | Float32 | Nil)
            end

            def to_sql : String
              if distinct?
                "AVG(DISTINCT #{alias_prefix}.#{field.db_column}) as #{alias_name}"
              else
                "AVG(#{alias_prefix}.#{field.db_column}) as #{alias_name}"
              end
            end
          end
        end
      end
    end
  end
end
