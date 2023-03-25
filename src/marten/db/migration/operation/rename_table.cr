module Marten
  module DB
    abstract class Migration
      module Operation
        class RenameTable < Base
          @old_name : String
          @new_name : String

          getter old_name
          getter new_name

          def initialize(old_name : String | Symbol, new_name : String | Symbol)
            @old_name = old_name.to_s
            @new_name = new_name.to_s
          end

          def describe : String
            "Rename #{@old_name} table to #{@new_name}"
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

          def optimize(operation : Base) : Optimization::Result
            if operation.references_table?(old_name) || operation.references_table?(new_name)
              Optimization::Result.failed
            else
              Optimization::Result.unchanged
            end
          end

          def references_column?(other_table_name : String, other_column_name : String) : Bool
            references_table?(other_table_name)
          end

          def references_table?(other_table_name : String) : Bool
            old_name == other_table_name || new_name == other_table_name
          end

          def serialize : String
            ECR.render "#{__DIR__}/templates/rename_table.ecr"
          end
        end
      end
    end
  end
end
