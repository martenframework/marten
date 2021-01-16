module Marten
  module DB
    abstract class Migration
      module Operation
        class ExecuteSQL < Base
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

          def serialize : String
            ECR.render "#{__DIR__}/templates/execute_sql.ecr"
          end
        end
      end
    end
  end
end
