module Marten
  module Routing
    module Parameter
      class String < Base
        regex /[^\/]+/

        def loads(value : String) : String
          value
        end

        def dumps(value : String) : String
          value
        end
      end
    end
  end
end
