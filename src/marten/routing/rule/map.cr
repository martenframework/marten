module Marten
  module Routing
    module Rule
      class Map < Base
        @regex : Regex
        @parameters : Hash(String, Parameter::Base)

        def initialize(@path : String, @map : Marten::Routing::Map, @name : String | Symbol)
          @regex, @parameters = path_to_regex(@path)
        end

        def resolve(path : String) : Nil | Match
          match = @regex.match(path)
          return if match.nil?

          new_path = path[match.end..]
          @map.rules.each do |rule|
            matched = rule.resolve(new_path)
            break matched unless matched.nil?
          end
        end
      end
    end
  end
end
