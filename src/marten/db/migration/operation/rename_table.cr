module Marten
  module DB
    abstract class Migration
      module Operation
        class RenameTable < Base
          @old_name : String
          @new_name : String

          def initialize(old_name : String | Symbol, new_name : String | Symbol)
            @old_name = old_name.to_s
            @new_name = new_name.to_s
          end

          def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, @new_name)
            schema_editor.rename_table(table, @old_name)
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, @old_name)
            schema_editor.rename_table(table, @new_name)
          end

          def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
            state.rename_table(app_label, @old_name, @new_name)
          end

          def serialize : String
            ECR.render "#{__DIR__}/templates/rename_table.ecr"
          end
        end
      end
    end
  end
end
