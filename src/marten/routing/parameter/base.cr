module Marten
  module Routing
    module Parameter
      abstract class Base
        @@regex : Regex = /^$/

        def self.regex(regex : Regex)
          @@regex = regex
        end

        def self.regex : Regex
          @@regex
        end

        abstract def loads(value : String)
        abstract def dumps(value) : String
      end
    end
  end
end
