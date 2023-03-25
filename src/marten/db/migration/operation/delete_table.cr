module Marten
  module DB
    abstract class Migration
      module Operation
        class DeleteTable < Base
          @name : String

          getter name

          def initialize(name : String | Symbol)
            @name = name.to_s
          end

          def describe : String
            "Delete #{@name} table"
          end

          def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = to_state.get_table(app_label, @name)
            schema_editor.create_table(table)
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, @name)
            schema_editor.delete_table(table)
          end

          def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
            state.delete_table(app_label, @name)
          end

          def optimize(operation : Base) : Optimization::Result
            operation.references_table?(name) ? Optimization::Result.failed : Optimization::Result.unchanged
          end

          def references_column?(other_table_name : String, other_column_name : String) : Bool
            references_table?(other_table_name)
          end

          def references_table?(other_table_name : String) : Bool
            true
          end

          def serialize : String
            ECR.render "#{__DIR__}/templates/delete_table.ecr"
          end
        end
      end
    end
  end
end
