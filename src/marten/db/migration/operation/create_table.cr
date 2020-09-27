module Marten
  module DB
    abstract class Migration
      module Operation
        class CreateTable < Base
          def initialize(@name : String, @columns : Array(Column::Base))
          end

          def state_forward(app_label : String, state : Management::Migrations::ProjectState) : Nil
            state.add_table(
              Management::Migrations::TableState.new(
                app_label,
                @name,
                @columns.dup
              )
            )
          end
        end
      end
    end
  end
end
