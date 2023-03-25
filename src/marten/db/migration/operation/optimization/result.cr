module Marten
  module DB
    abstract class Migration
      module Operation
        module Optimization
          # Represents the result of a migration operation optimization.
          class Result
            getter operations

            def self.completed(*ops : Operation::Base)
              operations = [] of Operation::Base
              operations += ops.to_a
              new(operations, ResultType::COMPLETED)
            end

            def self.completed
              new(ResultType::COMPLETED)
            end

            def self.failed
              new(ResultType::FAILED)
            end

            def self.unchanged
              new(ResultType::UNCHANGED)
            end

            def initialize(@operations : Array(Operation::Base), @type : ResultType)
            end

            def initialize(@type : ResultType)
              @operations = [] of Operation::Base
            end

            def completed?
              @type == ResultType::COMPLETED
            end

            def failed?
              @type == ResultType::FAILED
            end

            def unchanged?
              @type == ResultType::UNCHANGED
            end
          end
        end
      end
    end
  end
end
