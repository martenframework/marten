module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class Month < DateTimeBase
            predicate_name "month"
          end
        end
      end
    end
  end
end
