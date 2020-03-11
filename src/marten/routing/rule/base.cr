module Marten
  module Routing
    module Rule
      class Base
        def resolve(path : String) : Nil | Match
          nil
        end
      end
    end
  end
end
