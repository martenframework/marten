module Marten
  module Routing
    class Map
      getter rules
      getter reversers

      def self.draw
        map = new
        with map yield map
        map
      end

      def initialize(@name : Symbol | String = "")
        @rules = [] of Rule::Base
        @reversers = {} of String => Reverser
      end

      def draw
        with self yield self
      end

      def path(path : String, target : Marten::Views::Base.class | Map, name : String | Symbol)
        if target.is_a?(Marten::Views::Base.class)
          rule = Rule::Path.new(path, target, name.to_s)
        else  # Nested routes map
          rule = Rule::Map.new(path, target, name.to_s)
        end

        @rules << rule
        rule.reversers.each do |reverser|
          @reversers[reverser.name] = reverser
        end
      end

      def resolve(path : String) : Match
        match = @rules.each do |r|
          matched = r.resolve(path)
          break matched unless matched.nil?
        end

        raise Errors::NoResolveMatch.new if match.nil?
        match
      end

      def reverse(name : String, **kwargs) : String
        reversed = nil

        begin
          reverser = @reversers[name]
          reversed = reverser.reverse(**kwargs)
        rescue KeyError
          raise Errors::NoReverseMatch.new("'#{name}' does not match any registered route")
        end

        if reversed.nil?
          raise Errors::NoReverseMatch.new("'#{name}' route cannot receive #{kwargs} as parameters")
        end

        reversed
      end
    end
  end
end
