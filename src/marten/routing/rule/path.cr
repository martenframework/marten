module Marten
  module Routing
    module Rule
      class Path < Base
        @regex : Regex
        @parameters : Hash(String, Parameter::Base)

        getter name

        def initialize(@path : String, @view : Marten::Views::Base.class, @name : String | Symbol)
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

          Match.new(@view, kwargs)
        end

        private def path_to_regex(_path)
          regex, parameters = super
          { Regex.new("#{regex.source}$"), parameters }
        end
      end
    end
  end
end
