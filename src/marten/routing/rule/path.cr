module Marten
  module Routing
    module Rule
      class Path < Base
        @regex : Regex
        @path_for_interpolation : String
        @parameters : Hash(String, Parameter::Base)
        @endpoint_reversers : Nil | Array(EndpointReverser)

        getter name

        def initialize(@path : String, @view : Marten::Views::Base.class, @name : String)
          @regex, @path_for_interpolation, @parameters = path_to_regex(@path)
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

        def endpoint_reversers : Array(EndpointReverser)
          @endpoint_reversers ||= [
            EndpointReverser.new(@name, @path_for_interpolation, @parameters),
          ]
        end

        private def path_to_regex(_path)
          regex, path_for_interpolation, parameters = super
          { Regex.new("#{regex.source}$"), path_for_interpolation, parameters }
        end
      end
    end
  end
end
