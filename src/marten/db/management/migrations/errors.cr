module Marten
  module DB
    module Management
      module Migrations
        module Errors
          # Represents an error raised when a circular migration dependency is identified.
          class CircularDependency < Exception; end

          # Represents an error raised when an inexisting migration is requested when running migrations.
          class MigrationNotFound < Exception; end

          # Represents an error raised when an unknown node is requested from a specific migrations node.
          class UnknownNode < Exception; end
        end
      end
    end
  end
end
