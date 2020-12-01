module Marten
  module DB
    module Query
      class Expression
        class Filter(Model)
          def q(**kwargs)
            Node.new(**kwargs)
          end
        end
      end
    end
  end
end
