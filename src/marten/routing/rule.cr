module Marten
  module Routing
    class Rule
      getter path
      getter view
      getter name

      def initialize(@path : String, @view : Marten::Views::Base.class, @name : String | Symbol)
      end
    end
  end
end
