module Marten
  module DB
    module Management
      # Represents the state of the whole DB schema of the project at a specific step in a migration plan.
      class ProjectState
        @tables : Hash(String, TableState)

        getter tables

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

        def initialize(tables = [] of TableState)
          @tables = {} of String => TableState
          tables.each { |t| @tables[table_id(t.as(TableState))] = t }
        end

        # Returns a clone of the current project state.
        def clone
          ProjectState.new(@tables.values.map(&.clone))
        end

        # Adds a table state to the current project state.
        def add_table(table : TableState)
          @tables[table_id(table)] = table
        end

        # Deletes a table state from the current project state.
        def delete_table(app_label : String, name : String) : Nil
          @tables.delete(table_id(app_label, name))
        end

        # Returns the table state corresponding to the passed app label and table name.
        def get_table(app_label : String, name : String) : TableState
          @tables[table_id(app_label, name)]
        end

        # Renames a specific a table state.
        def rename_table(app_label : String, old_name : String, new_name : String) : Nil
          table = @tables.delete(table_id(app_label, old_name))
          table.not_nil!.name = new_name
          @tables[table_id(app_label, new_name)] = table.not_nil!
        end

        private def table_id(table)
          table_id(table.app_label, table.name)
        end

        private def table_id(app_label, table_name)
          "#{app_label}_#{table_name}"
        end
      end
    end
  end
end
