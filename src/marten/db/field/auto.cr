module Marten
  module DB
    module Field
      class Auto < Int
        include IsBuiltInField
        include IsAutoField
      end
    end
  end
end
