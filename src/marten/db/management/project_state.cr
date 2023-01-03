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
          tables.each { |t| @tables[t.as(TableState).id] = t }
          @tables.values.each(&.contribute_to_project(self))
        end

        # Returns a clone of the current project state.
        def clone
          ProjectState.new(@tables.values.map(&.clone))
        end

        # Adds a table state to the current project state.
        def add_table(table : TableState) : Nil
          @tables[table.id] = table
          table.contribute_to_project(self)
        end

        # Deletes a table state from the current project state.
        def delete_table(app_label : String, name : String) : Nil
          @tables.delete(table_id(app_label, name))
        end

        # Returns the table state corresponding to the passed app label and table name.
        def get_table(app_label : String, name : String) : TableState
          @tables[table_id(app_label, name)]
        end

        # Returns the table state corresponding to the passed table ID.
        def get_table(id : String) : TableState
          @tables[id]
        end

        # Renames a specific a table state.
        def rename_table(app_label : String, old_name : String, new_name : String) : Nil
          table = @tables.delete(table_id(app_label, old_name))
          table.not_nil!.name = new_name
          @tables[table_id(app_label, new_name)] = table.not_nil!
        end

        private def table_id(app_label, table_name)
          TableState.gen_id(app_label, table_name)
        end
      end
    end
  end
end
