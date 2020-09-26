module Marten
  module DB
    abstract class Migration
      module Operation
        abstract class Base
          abstract def state_forward(app_label : String, state : Management::Migrations::ProjectState) : Nil
        end
      end
    end
  end
end
