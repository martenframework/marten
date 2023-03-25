module Marten
  module DB
    abstract class Migration
      module Operation
        module Optimization
          # Defines the various types of results that can be returned by a migration operation optimization.
          enum ResultType
            # A "completed" result indicates that the considered migration operation was indeed optimized and that a new
            # set of operations should be used in lieu of the operation.
            COMPLETED

            # A "failed" result indicates that the considered migration operation cannot be optimized, which generally
            # means that that incoming operation used for optimizing has a dependency to the considered operation (for
            # example, a CreateTable operation that has a reference column to a table created by another CreateTable
            # operation).
            FAILED

            # An "unchanged" result indicates that no optimization can be done and that operations remain unchanged
            # (for example, two completely unrelated operations that cannot be further optimized).
            UNCHANGED
          end
        end
      end
    end
  end
end
