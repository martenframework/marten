module Marten
  module DB
    abstract class Migration
      module Operation
        class RemoveColumn < Base
          @table_name : String
          @column_name : String

          getter table_name
          getter column_name

          def initialize(table_name : String | Symbol, column_name : String | Symbol)
            @table_name = table_name.to_s
            @column_name = column_name.to_s
          end

          def describe : String
            "Remove #{@column_name} on #{@table_name} table"
          end

          def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, @table_name)
            column = to_state.get_table(app_label, @table_name).get_column(@column_name)
            schema_editor.add_column(table, column)
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, @table_name)
            column = table.get_column(@column_name)
            schema_editor.remove_column(table, column)
          end

          def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
            table = state.get_table(app_label, @table_name)
            table.remove_column(@column_name)
          end

          def optimize(operation : Base) : Optimization::Result
            if (op = operation).is_a?(DeleteTable) && table_name == op.name
              return Optimization::Result.completed(operation)
            end

            if operation.references_column?(table_name, column_name)
              Optimization::Result.failed
            else
              Optimization::Result.unchanged
            end
          end

          def references_column?(other_table_name : String, other_column_name : String) : Bool
            references_table?(other_table_name)
          end

          def references_table?(other_table_name : String) : Bool
            # We can't know exactly whether the other table is referenced at this operation level: since we only know
            # the name of the column being removed, we can't be sure that it's not a reference column that targets
            # another column. So we assume that tables are referenced in all case to not introduce inconsistencies in
            # generated migrations.
            true
          end

          def serialize : String
            ECR.render "#{__DIR__}/templates/remove_column.ecr"
          end
        end
      end
    end
  end
end
