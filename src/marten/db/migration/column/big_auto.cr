module Marten
  module DB
    abstract class Migration
      module Column
        class BigAuto < Base
          include IsBuiltInColumn
        end
      end
    end
  end
end
