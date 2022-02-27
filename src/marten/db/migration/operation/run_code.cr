module Marten
  module DB
    abstract class Migration
      module Operation
        class RunCode < Base
          getter forward_proc
          getter backward_proc

          def initialize(@forward_proc : Proc(Nil), @backward_proc : Proc(Nil)? = nil)
          end

          def describe : String
            "Run custom Crystal code"
          end

          def mutate_db_backward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            @backward_proc.not_nil!.call if !@backward_proc.nil?
          end

          def mutate_db_forward(
            app_label : String,
            schema_editor : Management::SchemaEditor::Base,
            from_state : Management::ProjectState,
            to_state : Management::ProjectState
          ) : Nil
            @forward_proc.call
          end

          def mutate_state_forward(app_label : String, state : Management::ProjectState) : Nil
            # noop
          end

          def serialize : String
            raise NotImplementedError.new("RunCode operations can't be serialized")
          end
        end
      end
    end
  end
end
