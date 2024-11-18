module Marten
  module Routing
    # Represents a route reverser.
    #
    # A route reverser allows to perform URL / route lookups for a given route. Such routes can optionally expect
    # parameters and such parameters are handled accordingly when the `#reverse` method is called. The main
    # `Marten::Routing::Map#reverse` method makes use of reverser objects internally in order to perform routes lookups.
    class Reverser
      getter name
      getter parameters

      def initialize(
        @name : String,
        path_for_interpolation : String,
        @parameters = {} of String => Parameter::Base
      )
        @path_for_interpolations = {} of String? => String
        @path_for_interpolations[nil] = path_for_interpolation
      end

      def initialize(
        @name : String,
        @path_for_interpolations : Hash(String?, String),
        @parameters = {} of String => Parameter::Base
      )
      end

      # Combines the current reverser with another reverser.
      #
      # The new reverser will have a combined name, path, and parameters.
      def combine(other : Reverser) : Reverser
        new_name = name.empty? ? other.name : "#{name}:#{other.name}"

        new_path_for_interpolations = Hash(String?, String).new
        @path_for_interpolations.each do |locale, path_for_interpolation|
          next if other.path_for_interpolations[locale]?.nil?

          new_path_for_interpolations[locale] = path_for_interpolation + other.path_for_interpolations[locale]
        end

        Reverser.new(
          new_name,
          new_path_for_interpolations,
          parameters.merge(other.parameters)
        )
      end

      # Returns the path for interpolation for the current locale.
      def path_for_interpolation : String
        @path_for_interpolations[I18n.locale]? || @path_for_interpolations[nil]
      end

      # Reverses the route for the given parameters.
      #
      # If the parameters do not match the expected parameters for the route, `nil` is returned.
      def reverse(params : Nil | Hash(String | Symbol, Parameter::Types)) : Nil | String
        url_params = {} of String => String

        params.each do |key, value|
          param_name = key.to_s

          # A parameter that is not present in the set of route parameter handler means that the lookup is not
          # successful.
          return if !@parameters.has_key?(param_name)

          dumped_value = @parameters[param_name].dumps(value)

          # If one of the parameter dumps result is nil, this means that the lookup is not successful because one of the
          # parameter handlers received a value it could not handle.
          return if dumped_value.nil?

          url_params[param_name] = dumped_value
        end unless params.nil?

        # if not all expected parameters were passed this means that the lookup is not successful.
        return unless url_params.size == @parameters.size

        path_for_interpolation % url_params
      end

      protected getter path_for_interpolations
    end
  end
end
