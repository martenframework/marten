module Marten
  module DB
    abstract class Migration
      module Operation
        class AddIndex < Base
          @table_name : String

          getter table_name
          getter index

          def initialize(table_name : String | Symbol, @index : Management::Index)
            @table_name = table_name.to_s
          end

          def describe : String
            "Add #{index.name} index to #{table_name} table"
          end

          def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, table_name)
            schema_editor.remove_index(table, index)
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            table = from_state.get_table(app_label, table_name)
            schema_editor.add_index(table, index)
          end

          def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
            table = state.get_table(app_label, table_name)
            table.add_index(index)
          end

          def optimize(operation : Base) : Optimization::Result
            operation.references_table?(table_name) ? Optimization::Result.failed : Optimization::Result.unchanged
          end

          def references_column?(other_table_name : String, other_column_name : String) : Bool
            table_name == other_table_name && index.column_names.includes?(other_column_name)
          end

          def references_table?(other_table_name : String) : Bool
            table_name == other_table_name
          end

          def serialize : String
            ECR.render "#{__DIR__}/templates/add_index.ecr"
          end
        end
      end
    end
  end
end
