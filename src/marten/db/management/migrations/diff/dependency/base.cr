module Marten
  module DB
    module Management
      module Migrations
        class Diff
          module Dependency
            # Abstract base class for generated migration operation dependencies.
            abstract class Base
              # Returns the app label associated with the dependency.
              abstract def app_label

              # Returns true if the given `operation` depends on the considered dependency.
              abstract def dependent?(operation : DB::Migration::Operation::Base) : Bool
            end
          end
        end
      end
    end
  end
end
