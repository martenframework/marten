module Marten
  module DB
    abstract class Migration
      module Column
        class Text < Base
          include IsBuiltInColumn
        end
      end
    end
  end
end
