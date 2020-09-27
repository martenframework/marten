module Marten
  module DB
    abstract class Migration
      module Column
        class Auto < Base
          include IsBuiltInColumn
        end
      end
    end
  end
end
