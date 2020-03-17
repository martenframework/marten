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

        def dumps(value) : Nil | ::String
          value.as?(::UUID) ? value.to_s : nil
        end
      end
    end
  end
end
