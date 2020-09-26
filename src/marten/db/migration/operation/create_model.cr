module Marten
  module DB
    abstract class Migration
      module Operation
        class CreateModel < Base
          def initialize(@name : String, @fields : Array(Field::Base))
          end

          def state_forward(app_label : String, state : Management::Migrations::ProjectState) : Nil
            state.add_model(
              Management::Migrations::ModelState.new(
                app_label,
                @name,
                @fields.dup
              )
            )
          end
        end
      end
    end
  end
end
