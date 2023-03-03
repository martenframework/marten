module Marten
  module Routing
    module Parameter
      class Integer < Base
        def dumps(value) : Nil | ::String
          if value.as?(UInt8 | UInt16 | UInt32 | UInt64)
            value.to_s
          elsif value.is_a?(Int8 | Int16 | Int32 | Int64) && value >= 0
            value.to_s
          else
            nil
          end
        end

        def loads(value : ::String) : UInt64
          value.to_u64
        end

        def regex : Regex
          REGEX
        end

        private REGEX = /[0-9]+/
      end
    end
  end
end
