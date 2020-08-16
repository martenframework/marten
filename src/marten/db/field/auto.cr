module Marten
  module DB
    module Field
      class Auto < Int
        include IsBuiltInField

        protected def perform_validation(_record : Model); end
      end
    end
  end
end
