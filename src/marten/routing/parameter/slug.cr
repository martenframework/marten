module Marten
  module Routing
    module Parameter
      class Slug < Base
        def dumps(value) : Nil | ::String
          value.as?(::String) ? value.to_s : nil
        end

        def loads(value : ::String) : ::String
          value
        end

        def regex : Regex
          REGEX
        end

        private REGEX = /[-a-zA-Z0-9_]+/
      end
    end
  end
end
