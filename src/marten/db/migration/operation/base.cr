module Marten
  module DB
    abstract class Migration
      module Operation
        abstract class Base
          abstract def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::Migrations::ProjectState,
            to_state : Management::Migrations::ProjectState
          ) : Nil

          abstract def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::Migrations::ProjectState,
            to_state : Management::Migrations::ProjectState
          ) : Nil

          abstract def mutate_state_backward(app_label : String, state : Management::Migrations::ProjectState) : Nil

          abstract def mutate_state_forward(app_label : String, state : Management::Migrations::ProjectState) : Nil
        end
      end
    end
  end
end
