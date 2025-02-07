module Marten
  module Routing
    # Represents a route reverser.
    #
    # A route reverser allows to perform URL / route lookups for a given route. Such routes can optionally expect
    # parameters and such parameters are handled accordingly when the `#reverse` method is called. The main
    # `Marten::Routing::Map#reverse` method makes use of reverser objects internally in order to perform routes lookups.
    class Reverser
      @prefix_default_locale : Bool = true
      @prefix_locales : Bool = false

      getter name
      getter parameters

      getter? prefix_default_locale
      getter? prefix_locales

      setter prefix_default_locale
      setter prefix_locales

      def initialize(
        @name : String,
        path_for_interpolation : String,
        @parameters = {} of String => Parameter::Base,
      )
        @path_for_interpolations = {} of String? => String
        @path_for_interpolations[nil] = path_for_interpolation
      end

      def initialize(
        @name : String,
        @path_for_interpolations : Hash(String?, String),
        @parameters = {} of String => Parameter::Base,
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
      def reverse(params : Nil | Hash(String | Symbol, Parameter::Types)) : String?
        url_params = {} of String => String
        params.each do |key, value|
          param_name = key.to_s

          # A parameter that is not present in the set of route parameter handler means that the lookup is not
          # successful.
          return unless @parameters.has_key?(param_name)

          dumped_value = @parameters[param_name].dumps(value)

          # If one of the parameter dumps result is nil, this means that the lookup is not successful because one of the
          # parameter handlers received a value it could not handle.
          return unless dumped_value

          url_params[param_name] = dumped_value
        end unless params.nil?

        # If not all expected parameters were passed this means that the lookup is not successful.
        return unless url_params.size == @parameters.size

        path = path_for_interpolation % url_params

        if prefix_locales? && (prefix_default_locale? || I18n.locale != Marten.settings.i18n.default_locale)
          "/#{I18n.locale}#{path}"
        else
          path
        end
      end

      def reverse_mismatch(params : Nil | Hash(String | Symbol, Parameter::Types)) : Mismatch
        mismatch = Mismatch.new
        provided = (params || Hash(String | Symbol, Parameter::Types).new).keys.map(&.to_s)
        expected = @parameters.keys

        mismatch.missing_params = expected - provided
        mismatch.extra_params = provided - expected

        params.try &.each do |k, v|
          param_name = k.to_s
          next unless expected.includes?(param_name)

          dumped = @parameters[param_name].dumps(v)
          mismatch.invalid_params << {param_name, v} if dumped.nil?
        end

        mismatch
      end

      struct Mismatch
        property missing_params : Array(String) = [] of String
        property extra_params : Array(String) = [] of String
        property invalid_params : Array(Tuple(String, Parameter::Types)) = [] of Tuple(String, Parameter::Types)
      end

      protected getter path_for_interpolations
    end
  end
end
