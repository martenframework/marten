module Marten
  module Routing
    module Parameter
      class UUID < Base
        private REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

        def regex : Regex
          REGEX
        end

        def loads(value : ::String) : ::UUID
          ::UUID.new(value)
        end

        def dumps(value : ::UUID) : ::String
          value.to_s
        end
      end
    end
  end
end
