module Marten
  module DB
    abstract class Migration
      module Operation
        class CreateTable < Base
          getter name
          getter columns
          getter indexes
          getter unique_constraints

          def initialize(
            @name : String,
            @columns : Array(Management::Column::Base),
            @unique_constraints : Array(Management::Constraint::Unique) = [] of Management::Constraint::Unique,
            @indexes : Array(Management::Index) = [] of Management::Index
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
                app_label: app_label,
                name: name,
                columns: columns.dup,
                unique_constraints: unique_constraints.dup,
                indexes: indexes.dup
              )
            )
          end

          def optimize(operation : Base) : Optimization::Result
            if (op = operation).is_a?(DeleteTable) && name == op.name
              # Nullify the creation/deletion of the table.
              return Optimization::Result.completed
            elsif (op = operation).is_a?(RenameTable) && name == op.old_name
              return Optimization::Result.completed(
                CreateTable.new(
                  name: op.new_name,
                  columns: columns,
                  indexes: indexes,
                  unique_constraints: unique_constraints
                )
              )
            elsif (op = operation).is_a?(AddColumn) && name == op.table_name
              return Optimization::Result.completed(
                CreateTable.new(
                  name: name,
                  columns: columns + [op.column],
                  indexes: indexes,
                  unique_constraints: unique_constraints
                )
              )
            elsif (op = operation).is_a?(ChangeColumn) && name == op.table_name
              return Optimization::Result.completed(
                CreateTable.new(
                  name: name,
                  columns: columns.map { |c| c.name == op.column.name ? op.column : c },
                  indexes: indexes,
                  unique_constraints: unique_constraints
                )
              )
            end

            operation.references_table?(name) ? Optimization::Result.failed : Optimization::Result.unchanged
          end

          def references_column?(other_table_name : String, other_column_name : String) : Bool
            return true if name == other_table_name && columns.any? { |c| c.name == other_column_name }

            self.columns.select(Management::Column::Reference).any? do |column|
              reference_column = column.as(Management::Column::Reference)
              reference_column.to_table == other_table_name && reference_column.to_column == other_column_name
            end
          end

          def references_table?(other_table_name : String) : Bool
            return true if name == other_table_name

            self.columns.select(Management::Column::Reference).any? do |column|
              reference_column = column.as(Management::Column::Reference)
              reference_column.to_table == other_table_name
            end
          end

          def serialize : String
            ECR.render "#{__DIR__}/templates/create_table.ecr"
          end
        end
      end
    end
  end
end
