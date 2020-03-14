module Marten
  module Routing
    class Match
      getter view
      getter kwargs

      def initialize(@view : Marten::Views::Base.class, @kwargs = {} of String => Parameter::Types)
      end
    end
  end
end
