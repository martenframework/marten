module Marten
  module Routing
    module Parameter
      class Slug < Base
        regex /[-a-zA-Z0-9_]+/

        def loads(value : ::String) : ::String
          value
        end

        def dumps(value) : Nil | ::String
          value.as?(::String) ? value.to_s : nil
        end
      end
    end
  end
end
