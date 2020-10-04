module Marten
  module DB
    abstract class Migration
      module Operation
        class CreateTable < Base
          def initialize(@name : String, @columns : Array(Column::Base))
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::Migrations::ProjectState,
            to_state : Management::Migrations::ProjectState
          ) : Nil
            table = to_state.get_table(app_label, @name)
            schema_editor.create_table(table)
          end

          def mutate_state_forward(app_label : String, state : Management::Migrations::ProjectState) : Nil
            state.add_table(
              Management::Migrations::TableState.new(
                app_label,
                @name,
                @columns.dup
              )
            )
          end
        end
      end
    end
  end
end
