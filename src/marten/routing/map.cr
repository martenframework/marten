module Marten
  module Routing
    class Map
      getter rules

      def self.draw
        map = new
        with map yield map
        map
      end

      def initialize(@name : Symbol | String = "")
        @rules = [] of Rule::Base
      end

      def draw
        with self yield self
      end

      def path(path : String, target : Marten::Views::Base.class | Map, name : String | Symbol)
        if target.is_a?(Marten::Views::Base.class)
          @rules << Rule::Path.new(path, target, name.to_s)
          return
        end

        # Process nested routes map.
        @rules << Rule::Map.new(path, target, name.to_s)
      end

      def resolve(path : String) : Match
        match = @rules.each do |r|
          matched = r.resolve(path)
          break matched unless matched.nil?
        end

        raise Errors::NoResolveMatch.new if match.nil?
        match
      end
    end
  end
end
