module Marten
  module Conf
    module Routing
      class Map
        getter rules

        def initialize
          @rules = [] of Rule
        end

        def draw
          yield self
        end

        def path(path : String, view : Marten::Views::Base.class, name : String | Symbol)
          @rules << Rule.new(path, view, name)
        end
      end
    end
  end
end
