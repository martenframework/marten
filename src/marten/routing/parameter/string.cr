module Marten
  module Routing
    module Parameter
      class String < Base
        def dumps(value) : Nil | ::String
          value.as?(::String) ? value.to_s : nil
        end

        def loads(value : ::String) : ::String
          value
        end

        def regex : Regex
          REGEX
        end

        private REGEX = /[^\/]+/
      end
    end
  end
end
