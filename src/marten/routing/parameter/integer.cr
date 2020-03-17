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

        def dumps(value) : Nil | ::String
          value.as?(Int16 | Int32 | Int64) ? value.to_s : nil
        end
      end
    end
  end
end
