require "./parameter"

module Marten
  module Routing
    # A hash of matched parameters.
    class MatchParameters < Hash(String, Parameter::Types)
      def [](key : String | Symbol)
        super(key.to_s)
      end

      def []?(key : String | Symbol)
        super(key.to_s)
      end

      def has_key?(key : String | Symbol)
        super(key.to_s)
      end

      def merge(other : MatchParameters)
        hash = MatchParameters.new
        hash.merge! self
        hash.merge! other
        hash
      end
    end
  end
end
