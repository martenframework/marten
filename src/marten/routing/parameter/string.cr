module Marten
  module Routing
    module Parameter
      class String < Base
        private REGEX = /[^\/]+/

        def regex : Regex
          REGEX
        end

        def loads(value : ::String) : ::String
          value
        end

        def dumps(value : ::String) : ::String
          value
        end
      end
    end
  end
end
