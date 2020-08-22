module Marten
  module DB
    abstract class Migration
      module Operation
        class CreateModel < Base
          def initialize(@name : String, @fields : Array(Field::Base))
          end
        end
      end
    end
  end
end
