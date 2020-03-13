module Marten
  module Routing
    module Parameter
      class Integer < Base
        private REGEX = /[0-9]+/

        def regex : Regex
          REGEX
        end

        def loads(value : ::String) : Int64
          value.to_i64
        end

        def dumps(value : Int16 | Int32 | Int64) : ::String
          value.to_s
        end
      end
    end
  end
end
