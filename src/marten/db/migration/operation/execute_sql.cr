module Marten
  module DB
    abstract class Migration
      module Operation
        class ExecuteSQL < Base
          getter forward_sql
          getter backward_sql

          def initialize(@forward_sql : String, @backward_sql : String? = nil)
          end

          def describe : String
            "Run raw SQL"
          end

          def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            schema_editor.execute(@backward_sql.not_nil!) unless @backward_sql.nil?
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            schema_editor.execute(@forward_sql)
          end

          def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
          end

          def optimize(operation : Base) : Optimization::Result
            # Return a failed optimization result to ensure this operation remains consistent with the initial ordering.
            Optimization::Result.failed
          end

          def references_column?(other_table_name : String, other_column_name : String) : Bool
            # We can't know whether the other column is referenced in case of arbitrary SQL statements, so we assume
            # that it is referenced.
            true
          end

          def references_table?(other_table_name : String) : Bool
            # We can't know whether the other table is referenced in case of arbitrary SQL statements, so we assume that
            # it is referenced.
            true
          end

          def serialize : String
            ECR.render "#{__DIR__}/templates/execute_sql.ecr"
          end
        end
      end
    end
  end
end
