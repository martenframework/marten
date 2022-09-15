module Marten
  module Routing
    # A route match, corresponding to a specific view plus the extracted route parameters.
    struct Match
      getter view
      getter kwargs

      def initialize(@view : Marten::Views::Base.class, @kwargs = {} of String => Parameter::Types)
      end
    end
  end
end
