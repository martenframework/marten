module Marten
  module DB
    class Expression
      class Filter(Model)
        def q(**kwargs)
          QueryNode(Model).new(**kwargs)
        end
      end
    end
  end
end
