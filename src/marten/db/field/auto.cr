module Marten
  module DB
    module Field
      class Auto < Int
        protected def perform_validation(_record : Model); end
      end
    end
  end
end
