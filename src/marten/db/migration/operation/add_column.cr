module Marten
  module DB
    abstract class Migration
      module Operation
        class AddColumn < Base
          @table_name : String

          def initialize(table_name : String | Symbol, @column : Management::Column::Base)
            @table_name = table_name.to_s
          end

          def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, @table_name)
            schema_editor.remove_column(table, @column)
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, @table_name)
            schema_editor.add_column(table, @column)
          end

          def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
            table = state.get_table(app_label, @table_name)
            table.add_column(@column)
          end
        end
      end
    end
  end
end
