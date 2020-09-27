module Marten
  module DB
    module Management
      module Migrations
        # Represents the state of the whole DB schema of the project at a specific step in a migration plan.
        class ProjectState
          # Initialize a project state from all the current tables of the project applications.
          def self.from_apps(apps : Array(Apps::Config))
            tables = [] of TableState

            apps.each do |app|
              app.models.each do |model|
                tables << TableState.from_model(model)
              end
            end

            new(tables)
          end

          def initialize(@tables = [] of TableState)
          end

          # Returns a clone of the current project state.
          def clone
            ProjectState.new(@tables.map(&.clone))
          end

          # Adds a table state to the current project state.
          def add_table(table : TableState)
            @tables << table
          end
        end
      end
    end
  end
end
