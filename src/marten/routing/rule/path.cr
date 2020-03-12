module Marten
  module Routing
    module Rule
      class Path < Base
        @regex : Regex
        @parameters : Hash(String, Parameter::Base)

        def initialize(@path : String, @view : Marten::Views::Base.class, @name : String | Symbol)
          @regex, @parameters = path_to_regex(@path)
        end

        def resolve(path : String) : Nil | Match
          match = @regex.match(path)
          return if match.nil?

          Match.new(@view)
        end

        private def path_to_regex(_path)
          regex, parameters = super
          { Regex.new("#{regex.source}$"), parameters }
        end
      end
    end
  end
end
