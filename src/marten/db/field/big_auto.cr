module Marten
  module DB
    module Field
      class BigAuto < BigInt
        protected def perform_validation(_record : Model); end
      end
    end
  end
end
