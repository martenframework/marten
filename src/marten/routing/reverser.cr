module Marten
  module Routing
    # Represents a route reverser.
    #
    # A route reverser allows to perform URL / route lookups for a given route. Such routes can optionally expect
    # parameters and such parameters are handled accordingly when the `#reverse` method is called. The main
    # `Marten::Routing::Map#reverse` method makes use of reverser objects internally in order to perform routes lookups.
    class Reverser
      getter name
      getter path_for_interpolation
      getter parameters

      def initialize(
        @name : String,
        @path_for_interpolation : String,
        @parameters = {} of String => Parameter::Base
      )
      end

      def reverse(**kwargs) : Nil | String
        url_kwargs = {} of String => String

        kwargs.each do |key, value|
          param_name = key.to_s

          # A parameter that is not present in the set of route parameter handler means that the lookup is not
          # successful.
          return if !@parameters.has_key?(param_name)

          dumped_value = @parameters[param_name].dumps(value)

          # If one of the parameter dumps result is nil, this means that the lookup is not successful because one of the
          # parameter handlers received a value it could not handle.
          return if dumped_value.nil?

          url_kwargs[param_name] = dumped_value
        end

        # if not all expected parameters were passed this means that the lookup is not successful.
        return unless url_kwargs.size == @parameters.size

        @path_for_interpolation % url_kwargs
      end
    end
  end
end
