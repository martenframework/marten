module Marten
  module DB
    abstract class Migration
      module Operation
        class AddColumn < Base
          @table_name : String

          getter table_name
          getter column

          def initialize(table_name : String | Symbol, @column : Management::Column::Base)
            @table_name = table_name.to_s
          end

          def describe : String
            "Add #{@column.name} to #{@table_name} table"
          end

          def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            column = @column.clone
            column.contribute_to_project(from_state)

            table = from_state.get_table(app_label, @table_name)
            schema_editor.remove_column(table, column)
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            column = @column.clone
            column.contribute_to_project(from_state)

            table = from_state.get_table(app_label, @table_name)
            schema_editor.add_column(table, column)
          end

          def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
            table = state.get_table(app_label, @table_name)
            column = @column.clone
            column.contribute_to_project(state)
            table.add_column(column)
          end

          def optimize(operation : Base) : Optimization::Result
            if (op = operation).is_a?(ChangeColumn) && table_name == op.table_name && column.name == op.column.name
              return Optimization::Result.completed(AddColumn.new(table_name: table_name, column: op.column))
            elsif (op = operation).is_a?(RemoveColumn) && table_name == op.table_name && column.name == op.column_name
              return Optimization::Result.completed
            elsif (op = operation).is_a?(RenameColumn) && table_name == op.table_name && column.name == op.old_name
              new_column = column.clone
              new_column.name = op.new_name
              return Optimization::Result.completed(AddColumn.new(table_name: table_name, column: new_column))
            end

            if operation.references_column?(table_name, column.name)
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
            ECR.render "#{__DIR__}/templates/add_column.ecr"
          end
        end
      end
    end
  end
end
