module Marten
  module DB
    abstract class Migration
      module Operation
        class ChangeColumn < Base
          @table_name : String

          getter table_name
          getter column

          def initialize(table_name : String | Symbol, @column : Management::Column::Base)
            @table_name = table_name.to_s
          end

          def describe : String
            "Change #{@column.name} on #{@table_name} table"
          end

          def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, @table_name)
            old_column = to_state.get_table(app_label, @table_name).get_column(column.name)
            column.contribute_to_project(to_state)
            schema_editor.change_column(from_state, table, column, old_column)
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, @table_name)
            old_column = table.get_column(column.name)
            column.contribute_to_project(to_state)
            schema_editor.change_column(from_state, table, old_column, column)
          end

          def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
            table = state.get_table(app_label, @table_name)
            table.change_column(column)
          end

          def optimize(operation : Base) : Optimization::Result
            if (op = operation).is_a?(RemoveColumn) && table_name == op.table_name && column.name == op.column_name
              Optimization::Result.completed(operation)
            elsif operation.references_column?(table_name, column.name)
              Optimization::Result.failed
            else
              Optimization::Result.unchanged
            end
          end

          def references_column?(other_table_name : String, other_column_name : String) : Bool
            return true if table_name == other_table_name && column.name == other_column_name

            if (reference_column = column).is_a?(Management::Column::Reference?)
              return reference_column.to_table == other_table_name && reference_column.to_column == other_column_name
            end

            false
          end

          def references_table?(other_table_name : String) : Bool
            return true if table_name == other_table_name

            if (reference_column = column).is_a?(Management::Column::Reference?)
              return reference_column.to_table == other_table_name
            end

            false
          end

          def serialize : String
            ECR.render "#{__DIR__}/templates/change_column.ecr"
          end
        end
      end
    end
  end
end
