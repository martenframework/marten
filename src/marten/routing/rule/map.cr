module Marten
  module Routing
    module Rule
      class Map < Base
        @regex : Regex
        @parameters : Hash(String, Parameter::Base)

        getter name

        def initialize(@path : String, @map : Marten::Routing::Map, @name : String | Symbol)
          @regex, @parameters = path_to_regex(@path)
        end

        def resolve(path : String) : Nil | Match
          match = @regex.match(path)
          return if match.nil?

          kwargs = {} of String => Parameter::Types
          match.named_captures.each do |name, value|
            param_handler = @parameters[name]
            kwargs[name] = param_handler.loads(value.to_s)
          end

          new_path = path[match.end..]
          sub_match = @map.rules.each do |rule|
            matched = rule.resolve(new_path)
            break matched unless matched.nil?
          end

          return if sub_match.nil?

          Match.new(sub_match.view, kwargs.merge(sub_match.kwargs))
        end
      end
    end
  end
end
