module Marten
  module DB
    abstract class Migration
      module Operation
        class RenameColumn < Base
          @table_name : String
          @old_name : String
          @new_name : String

          getter table_name
          getter old_name
          getter new_name

          def initialize(table_name : String | Symbol, old_name : String | Symbol, new_name : String | Symbol)
            @table_name = table_name.to_s
            @old_name = old_name.to_s
            @new_name = new_name.to_s
          end

          def describe : String
            "Rename #{@old_name} on #{@table_name} table to #{@new_name}"
          end

          def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, @table_name)
            column = table.get_column(@new_name)
            schema_editor.rename_column(table, column, @old_name)
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, @table_name)
            column = table.get_column(@old_name)
            schema_editor.rename_column(table, column, @new_name)
          end

          def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
            table = state.get_table(app_label, @table_name)
            table.rename_column(@old_name, @new_name)
          end

          def optimize(operation : Base) : Optimization::Result
            if operation.references_column?(table_name, old_name) || operation.references_column?(table_name, new_name)
              Optimization::Result.failed
            else
              Optimization::Result.unchanged
            end
          end

          def references_column?(other_table_name : String, other_column_name : String) : Bool
            if table_name == other_table_name
              return old_name == other_column_name || new_name == other_column_name
            end

            references_table?(other_table_name)
          end

          def references_table?(other_table_name : String) : Bool
            # We can't know exactly whether the other table is referenced at this operation level: since we only know
            # the old/new name of the column, we can't be sure that it's not a reference column that targets another
            # column. So we assume that tables are referenced in all case to not introduce inconsistencies in generated
            # migrations.
            true
          end

          def serialize : String
            ECR.render "#{__DIR__}/templates/rename_column.ecr"
          end
        end
      end
    end
  end
end
