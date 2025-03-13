module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class Year < DateTimeBase
            predicate_name "year"
          end
        end
      end
    end
  end
end
