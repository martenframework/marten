module Marten
  module DB
    abstract class Migration
      module Column
        class Bool < Base
          include IsBuiltInColumn
        end
      end
    end
  end
end
