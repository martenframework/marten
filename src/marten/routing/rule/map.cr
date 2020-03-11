module Marten
  module Routing
    module Rule
      class Map < Base
        @regex : Regex

        def initialize(@path : String, @map : Marten::Routing::Map, @name : String | Symbol)
          @regex = path_to_regex(@path)
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

        private def path_to_regex(path)
          parts = ["^", path]
          Regex.new(parts.join(""))
        end
      end
    end
  end
end
