module Marten
  module DB
    module Field
      class BigAuto < BigInt
        include IsBuiltInField

        protected def perform_validation(_record : Model); end
      end
    end
  end
end
