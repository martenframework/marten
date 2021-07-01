module Marten
  module DB
    module Management
      # Represents the state of a specific table at a specific step in a migration plan.
      class TableState
        getter app_label
        getter columns
        getter name
        getter unique_constraints

        setter name

        # Initializes a table state from a specific model class.
        def self.from_model(model : Model.class)
          new(
            app_label: model.app_config.label,
            name: model.db_table,
            columns: model.fields.compact_map(&.to_column),
            unique_constraints: model.db_unique_constraints.map(&.to_management_constraint)
          )
        end

        def initialize(
          @app_label : String,
          @name : String,
          @columns : Array(Column::Base),
          @unique_constraints : Array(Management::Constraint::Unique)
        )
        end

        def add_column(column : Column::Base) : Nil
          @columns << column
        end

        def add_unique_constraint(unique_constraint : Management::Constraint::Unique) : Nil
          @unique_constraints << unique_constraint
        end

        def get_column(name : String) : Column::Base
          @columns.find { |c| c.name == name }.not_nil!
        end

        def get_unique_constraint(name : String) : Management::Constraint::Unique
          unique_constraints.find { |c| c.name == name }.not_nil!
        end

        def remove_column(column : Column::Base)
          @columns.reject! { |c| c.name == column.name }
        end

        def remove_column(column_name : String)
          @columns.reject! { |c| c.name == column_name }
        end

        def remove_unique_constraint(unique_constraint : Management::Constraint::Unique) : Nil
          @unique_constraints.reject! { |c| c.name == unique_constraint.name }
        end

        def rename_column(old_name : String, new_name : String)
          get_column(old_name).name = new_name
        end

        def clone
          TableState.new(@app_label.dup, @name.dup, @columns.clone, @unique_constraints.clone)
        end
      end
    end
  end
end
