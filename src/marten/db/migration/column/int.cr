module Marten
  module DB
    abstract class Migration
      module Column
        class Int < Base
          include IsBuiltInColumn
        end
      end
    end
  end
end
