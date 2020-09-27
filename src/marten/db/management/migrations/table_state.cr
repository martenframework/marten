module Marten
  module DB
    module Management
      module Migrations
        # Represents the state of a specific table at a specific step in a migration plan.
        class TableState
          # Initializes a table state from a specific model class.
          def self.from_model(model : Model.class)
            new(
              app_label: model.app_config.label,
              name: model.db_table,
              columns: model.fields.map(&.to_column)
            )
          end

          def initialize(
            @app_label : String,
            @name : String,
            @columns : Array(Migration::Column::Base)
          )
          end

          def clone
            TableState.new(@app_label.dup, @name.dup, @columns.dup)
          end
        end
      end
    end
  end
end
