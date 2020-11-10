module Marten
  module DB
    module Management
      # Represents the state of a specific table at a specific step in a migration plan.
      class TableState
        getter app_label
        getter columns
        getter name

        setter name

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
          @columns : Array(Column::Base)
        )
        end

        def add_column(column : Column::Base)
          @columns << column
        end

        def get_column(name : String) : Column::Base
          @columns.find { |c| c.name == name }.not_nil!
        end

        def remove_column(column : Column::Base)
          @columns.reject! { |c| c.name == column.name }
        end

        def remove_column(column_name : String)
          @columns.reject! { |c| c.name == column_name }
        end

        def clone
          TableState.new(@app_label.dup, @name.dup, @columns.dup)
        end
      end
    end
  end
end
