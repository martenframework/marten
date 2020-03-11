module Marten
  module Routing
    module Rule
      class Path < Base
        @regex : Regex

        def initialize(@path : String, @view : Marten::Views::Base.class, @name : String | Symbol)
          @regex = path_to_regex(@path)
        end

        def resolve(path : String) : Nil | Match
          match = @regex.match(path)
          return if match.nil?

          Match.new(@view)
        end

        private def path_to_regex(path)
          parts = ["^", path, "$"]
          Regex.new(parts.join(""))
        end
      end
    end
  end
end
