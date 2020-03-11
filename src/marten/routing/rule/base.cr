module Marten
  module Routing
    module Rule
      abstract class Base
        abstract def resolve(path : String) : Nil | Match
      end
    end
  end
end
