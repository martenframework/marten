module Marten
  module DB
    abstract class Migration
      module Column
        class DateTime < Base
          include IsBuiltInColumn
        end
      end
    end
  end
end
