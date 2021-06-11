module Marten
  module DB
    abstract class Migration
      module Operation
        class CreateTable < Base
          getter name
          getter columns
          getter unique_constraints

          def initialize(
            @name : String,
            @columns : Array(Management::Column::Base),
            @unique_constraints : Array(Management::Constraint::Unique)
          )
          end

          def describe : String
            "Create #{@name} table"
          end

          def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, @name)
            schema_editor.delete_table(table)
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = to_state.get_table(app_label, @name)
            schema_editor.create_table(table)
          end

          def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
            state.add_table(
              Management::TableState.new(
                app_label,
                @name,
                @columns.dup,
                @unique_constraints.dup
              )
            )
          end

          def serialize : String
            ECR.render "#{__DIR__}/templates/create_table.ecr"
          end
        end
      end
    end
  end
end
