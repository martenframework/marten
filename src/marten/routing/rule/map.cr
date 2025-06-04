module Marten
  module Routing
    module Rule
      class Map < Base
        @path_info : Routing::Path::Spec::Base
        @reversers : Array(Reverser)?

        getter map
        getter name
        getter path

        def initialize(@path : String | TranslatedPath, @map : Marten::Routing::Map, @name : String)
          @path_info = path_to_path_info(path)
        end

        def resolve(path : String) : Nil | Match
          match = @path_info.resolve(path)
          return if match.nil?

          new_path = path[match.end_index..]
          sub_match = @map.rules.each do |rule|
            matched = rule.resolve(new_path)
            break matched unless matched.nil?
          end

          return if sub_match.nil?

          Match.new(handler: sub_match.handler, kwargs: match.parameters.merge(sub_match.kwargs), rule: sub_match.rule)
        end

        protected def reversers : Array(Reverser)
          @reversers ||= @map.reversers.values.map do |reverser|
            @path_info.reverser(@name).combine(reverser)
          end
        end
      end
    end
  end
end
