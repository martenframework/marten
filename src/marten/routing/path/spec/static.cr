require "./base"

module Marten
  module Routing
    module Path
      module Spec
        # Represents a static path specification.
        #
        # A static path specification is used for non-translated paths. Such specifications are derived from a set of
        # parameters, a path for interpolation, and a path regex.
        class Static < Base
          getter parameters
          getter path_for_interpolation
          getter regex

          def initialize(
            @regex : Regex,
            @path_for_interpolation : String,
            @parameters : Hash(String, Parameter::Base)
          )
          end

          def resolve(path : String) : Path::Match?
            match = @regex.match(path)
            return if match.nil?

            kwargs = MatchParameters.new
            match.named_captures.each do |name, value|
              param_handler = @parameters[name]
              kwargs[name] = param_handler.loads(value.to_s)
            end

            Path::Match.new(kwargs, match.end)
          end

          def reverser(name : String) : Reverser
            Reverser.new(name, @path_for_interpolation, @parameters)
          end
        end
      end
    end
  end
end
