module Marten
  module DB
    module Management
      # Represents the state of a specific table at a specific step in a migration plan.
      class TableState
        getter app_label
        getter columns
        getter indexes
        getter name
        getter unique_constraints

        setter name

        # Initializes a table state from a specific model class.
        def self.from_model(model : Model.class)
          new(
            app_label: model.app_config.label,
            name: model.db_table,
            columns: model.fields.compact_map(&.to_column),
            unique_constraints: model.db_unique_constraints.map { |c| Management::Constraint::Unique.from(c) },
            indexes: model.db_indexes.map { |i| Management::Index.from(i) },
          )
        end

        def self.gen_id(app_label : String, table_name : String)
          "#{app_label}_#{table_name}"
        end

        def initialize(
          @app_label : String,
          @name : String,
          @columns : Array(Column::Base),
          @unique_constraints : Array(Management::Constraint::Unique) = [] of Management::Constraint::Unique,
          @indexes : Array(Management::Index) = [] of Management::Index
        )
        end

        def add_column(column : Column::Base) : Nil
          @columns << column
        end

        def add_index(index : Management::Index) : Nil
          @indexes << index
        end

        def add_unique_constraint(unique_constraint : Management::Constraint::Unique) : Nil
          @unique_constraints << unique_constraint
        end

        def change_column(column : Column::Base) : Nil
          index = columns.index { |c| c.name == column.name }
          columns[index.not_nil!] = column
        end

        def get_column(name : String) : Column::Base
          @columns.find! { |c| c.name == name }
        end

        def get_index(name : String) : Management::Index
          indexes.find! { |i| i.name == name }
        end

        def get_unique_constraint(name : String) : Management::Constraint::Unique
          unique_constraints.find! { |c| c.name == name }
        end

        def id : String
          self.class.gen_id(app_label, name)
        end

        def remove_column(column : Column::Base)
          @columns.reject! { |c| c.name == column.name }
        end

        def remove_column(column_name : String)
          @columns.reject! { |c| c.name == column_name }
        end

        def remove_index(index : Management::Index) : Nil
          @indexes.reject! { |i| i.name == index.name }
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

        # :nodoc:
        def contribute_to_project(project : ProjectState) : Nil
          columns.each(&.contribute_to_project(project))
        end
      end
    end
  end
end
