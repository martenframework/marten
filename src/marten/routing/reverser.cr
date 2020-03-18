module Marten
  module Routing
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
          return if !@parameters.has_key?(param_name)

          dumped_value = @parameters[param_name].dumps(value)
          return if dumped_value.nil?

          url_kwargs[param_name] = dumped_value
        end

        return unless url_kwargs.size == @parameters.size

        @path_for_interpolation % url_kwargs
      end
    end
  end
end
