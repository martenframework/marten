module Marten
  module Routing
    class Reverser
      struct Mismatch
        property missing_params : Array(String) = [] of String
        property extra_params : Array(String) = [] of String
        property invalid_params : Array(Tuple(String, Parameter::Types)) = [] of Tuple(String, Parameter::Types)
      end
    end
  end
end
