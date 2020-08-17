module Marten
  module DB
    module Field
      class BigAuto < BigInt
        include IsBuiltInField
        include IsAutoField
      end
    end
  end
end
