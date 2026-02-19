require "./time_part"

module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class Year < TimePart
            predicate_name "year"

            protected def extract_time_part(value : Time) : Int64
              value.year.to_i64
            end
          end
        end
      end
    end
  end
end
