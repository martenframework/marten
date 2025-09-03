module Marten
  module DB
    module Query
      module SQL
        module Predicate
          # Base class for time-based transform predicates
          abstract class TransformBase < Base
            def self.apply(field : Field::Base) : SQL::Expression::Extract
              SQL::Expression::Extract.new(field, predicate_name)
            end
          end
        end
      end
    end
  end
end
