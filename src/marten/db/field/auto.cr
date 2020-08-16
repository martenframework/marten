module Marten
  module DB
    module Field
      class Auto < Int
        include IsBuiltInField

        def initialize(id, **kwargs)
          super
          @primary_key = true
        end

        protected def perform_validation(_record : Model); end
      end
    end
  end
end
