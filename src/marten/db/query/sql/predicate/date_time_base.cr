module Marten
  module DB
    module Query
      module SQL
        module Predicate
          class DateTimeBase < Base
            def self.apply(field : Field::Base) : SQL::Expression::Base
              SQL::Expression::Extract.new(field, predicate_name)
            end
          end
        end
      end
    end
  end
end
