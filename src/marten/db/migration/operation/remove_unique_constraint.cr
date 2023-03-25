module Marten
  module DB
    abstract class Migration
      module Operation
        class RemoveUniqueConstraint < Base
          @table_name : String
          @unique_constraint_name : String

          getter table_name
          getter unique_constraint_name

          def initialize(table_name : String | Symbol, unique_constraint_name : String | Symbol)
            @table_name = table_name.to_s
            @unique_constraint_name = unique_constraint_name.to_s
          end

          def describe : String
            "Remove #{unique_constraint_name} unique constraint from #{table_name} table"
          end

          def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, table_name)
            unique_constraint = to_state.get_table(app_label, table_name).get_unique_constraint(unique_constraint_name)
            schema_editor.add_unique_constraint(table, unique_constraint)
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, table_name)
            unique_constraint = table.get_unique_constraint(unique_constraint_name)
            schema_editor.remove_unique_constraint(table, unique_constraint)
          end

          def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
            table = state.get_table(app_label, table_name)
            unique_constraint = table.get_unique_constraint(unique_constraint_name)
            table.remove_unique_constraint(unique_constraint)
          end

          def optimize(operation : Base) : Optimization::Result
            operation.references_table?(table_name) ? Optimization::Result.failed : Optimization::Result.unchanged
          end

          def references_column?(other_table_name : String, other_column_name : String) : Bool
            references_table?(other_table_name)
          end

          def references_table?(other_table_name : String) : Bool
            table_name == other_table_name
          end

          def serialize : String
            ECR.render "#{__DIR__}/templates/remove_unique_constraint.ecr"
          end
        end
      end
    end
  end
end
