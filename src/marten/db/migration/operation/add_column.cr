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

          def serialize : String
            ECR.render "#{__DIR__}/templates/add_column.ecr"
          end
        end
      end
    end
  end
end
