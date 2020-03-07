module Marten
  module Conf
    module Routing
      class Rule
        getter path
        getter view

        def initialize(@path : String, @view : Marten::Views::Base.class, @name : String | Symbol)
        end
      end
    end
  end
end
