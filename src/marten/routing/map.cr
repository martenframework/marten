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
        @rules = [] of Rule
      end

      def draw
        with self yield self
      end

      def path(path : String, target : Marten::Views::Base.class | Map, name : String | Symbol)
        if target.is_a?(Marten::Views::Base.class)
          @rules << Rule.new(path, target, name.to_s)
          return
        end

        # Process nested routes map.
        target.rules.each do |rule|
          @rules << Rule.new(path + rule.path, rule.view, "#{name}:#{rule.name}")
        end
      end
    end
  end
end
