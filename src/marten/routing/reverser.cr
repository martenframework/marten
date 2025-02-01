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
      def reverse(params : Nil | Hash(String | Symbol, Parameter::Types)) : ReverseResult
        # Convert keys to string
        provided_param_names = (params || Hash(String | Symbol, Parameter::Types).new).keys.map(&.to_s)
        expected_param_names = @parameters.keys

        # Determine missing vs. extra right away
        missing = expected_param_names - provided_param_names
        extra = provided_param_names - expected_param_names

        # We’ll store invalid typed parameters here
        invalid = [] of Tuple(String, Parameter::Types)

        # If user has provided any param name that isn't expected, or we are missing any that are expected:
        if !missing.empty? || !extra.empty?
          return ReverseResult.new(ReverseResult::Mismatch.new(missing, extra, invalid))
        end

        # Attempt to dump each provided param into a string, track any that fail
        url_params = {} of String => String
        params.try &.each do |key, value|
          param_name = key.to_s
          dumped = @parameters[param_name].dumps(value)

          if dumped.nil?
            invalid << {param_name, value}
          else
            url_params[param_name] = dumped
          end
        end

        return ReverseResult.new(ReverseResult::Mismatch.new(missing, extra, invalid)) unless invalid.empty?

        # Everything is okay so far. We can build the path:
        path = path_for_interpolation % url_params

        # Handle locale prefix if needed
        if prefix_locales? && (prefix_default_locale? || I18n.locale != Marten.settings.i18n.default_locale)
          ReverseResult.new("/#{I18n.locale}#{path}")
        else
          ReverseResult.new(path)
        end
      end

      protected getter path_for_interpolations
    end
  end
end
