module Marten
  module DB
    class Expression
      class Filter(Model)
        def q(**kwargs)
          Q(Model).new(**kwargs)
        end
      end
    end
  end
end
