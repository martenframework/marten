require "./path/**"
require "./rule/**"

module Marten
  module Routing
    class Map
      @localized_rule : Rule::Localized? = nil
      @localizing : Bool = false
      @reversers : Hash(String, Reverser)? = nil
      @root : Bool = false

      getter rules

      def self.draw(namespace : String | Symbol | Nil = nil, &)
        map = new(namespace)
        with map yield map
        map
      end

      def initialize(@namespace : String | Symbol | Nil = nil)
        @rules = [] of Rule::Base
      end

      def draw(&)
        with self yield self
      end

      # Allows to define routes that are localized.
      #
      # When localized routes are defined, the current locale will be automatically prepended to the path of the
      # localized routes and the routes map will be able to resolve paths in a locale-aware manner. By default, the
      # locale prefix will be added to the path of the localized routes for all locales (including the default
      # locale). It is however possible to customize this behavior by passing `false` to the `prefix_default_locale`
      # argument (so that the locale prefix is not added for the default locale).
      #
      # For example:
      #
      # ```
      # Marten::Routing::Map.draw do
      #   localized do
      #     path t("routes.blog"), Blogging::BlogHandler, name: "blog"
      #     path t("routes.post_detail"), Blogging::PostHandler, name: "post_detail"
      #   end
      # end
      # ```
      def localized(prefix_default_locale = true, &) : Nil
        raise Errors::InvalidRouteMap.new("Cannot define localized routes in a non-root map") if !root?
        raise Errors::InvalidRouteMap.new("Cannot define nested localized routes") if localizing?
        raise Errors::InvalidRouteMap.new("Cannot define multiple localized rules") if !localized_rule.nil?

        begin
          previous_localizing = localizing?

          self.localizing = true
          self.localized_rule = Rule::Localized.new(prefix_default_locale)

          with self yield self
        ensure
          self.rules << localized_rule.not_nil!
          self.localizing = (previous_localizing == true)
        end
      end

      # Inserts a new path into the routes map.
      #
      # The target associated with the considered path must be a `Marten::Routing::Map`
      # instance. The <path, target> pair has an optional
      # name that will be prepended to each <path, target> pair inside the `Marten::Routing::Map`.
      def path(path : String, target : Map, name : String | Symbol | Nil = nil) : Nil
        insert_path(path, target, name)
      end

      # Inserts a new path into the routes map.
      #
      # The target associated with the considered path must be a handler (subclass of `Marten::Handlers::Base`).
      # Each <path, target> pair must be given a name that will be used to uniquely identify the route.
      def path(path : String | TranslatedPath, target : Marten::Handlers::Base.class, name : String | Symbol) : Nil
        insert_path(path, target, name)
      end

      # Returns a translated path.
      #
      # `path` must be a valid translation key.
      def t(path : String) : TranslatedPath
        TranslatedPath.new(path)
      end

      # Resolves a path - identify a route matching a specific path.
      #
      # The route resolution process tries to identify which handler corresponds to the considered path and returns a
      # `Marten::Routing::Match` object if a match is found. If no match is found a
      # `Marten::Routing::Errors::NoResolveMatch` exception is raised.
      def resolve(path : String) : Match
        match = rules.each do |r|
          matched = r.resolve(path)
          break matched unless matched.nil?
        end

        raise Errors::NoResolveMatch.new if match.nil?
        match
      end

      # Reverses a URL - returns the URL corresponding to a specific route name and parameters.
      #
      # The URL lookup mechanism tries to identify the route matching the given name and tries to apply any extra
      # parameters passed in the method call. If no route is found or if the arguments can't be applied to the route, a
      # `Marten::Routing::Errors::NoReverseMatch` exception is raised.
      def reverse(name : String | Symbol, **kwargs) : String
        params = Hash(String | Symbol, Parameter::Types).new
        kwargs.each do |key, value|
          params[key] = value
        end
        perform_reverse(name.to_s, params)
      end

      # Reverses a URL - returns the URL corresponding to a specific route name and hash of parameters.
      #
      # The URL lookup mechanism tries to identify the route matching the given name and tries to apply the parameters
      # defined in the parameters hash passed in the method call. If no route is found or if the arguments can't be
      # applied to the route, a `Marten::Routing::Errors::NoReverseMatch` exception is raised.
      def reverse(name : String | Symbol, params : Hash(String | Symbol, Parameter::Types))
        perform_reverse(name.to_s, params)
      end

      protected getter localized_rule
      protected getter namespace

      protected getter? root

      protected setter root

      protected def reversers : Hash(String, Reverser)
        @reversers ||= begin
          h = {} of String => Reverser

          rules.each do |rule|
            # Inserts the reversers associated with the newly added rule to the local list of reversers in order to ease
            # later reverse operations. No paths with duplicated params are allowed.
            rule.reversers.each do |reverser|
              if path_with_duplicated_parameters?(reverser.path_for_interpolation)
                raise Errors::InvalidRulePath.new(
                  "The '#{reverser.name}' route contains duplicated parameters: " \
                  "#{reverser.path_for_interpolation}"
                )
              end

              h[reverser.name] = reverser
            end
          end

          h
        end
      end

      protected def setup : Nil
        # Ensure that the reversers are reloaded when the routes are setup.
        @reversers = nil
        rules.select(Rule::Map).each { |rule| rule.as(Rule::Map).map.setup }

        reversers
      end

      private INTERPOLATION_PARAMETER_RE = /%{([a-zA-Z_0-9]+)}/

      private getter? localizing

      private setter localized_rule
      private setter localizing

      private def insert_path(
        path : String | TranslatedPath,
        target : Marten::Handlers::Base.class | Map,
        rule_name : String | Symbol | Nil,
      ) : Nil
        name = rule_name.to_s

        unless rule_name.nil?
          raise Errors::InvalidRuleName.new("Route names cannot be empty") if name.empty?

          if name.includes?(':')
            raise Errors::InvalidRuleName.new(
              "Cannot use '#{name}' as a valid route name: route names cannot contain ':'"
            )
          end
        end

        rules_to_check = localizing? ? rules + localized_rule.not_nil!.rules : rules
        rules_to_check = rules_to_check.flat_map do |rule|
          if rule.is_a?(Rule::Localized)
            rule.rules
          else
            rule
          end
        end

        unless rules_to_check.reject(Rule::Localized).find { |r| r.name == name }.nil?
          raise Errors::InvalidRuleName.new("A '#{name}' route already exists")
        end

        if target.is_a?(Marten::Handlers::Base.class)
          rule = Rule::Path.new(path, target, name.to_s)
        else # Nested routes map
          # Use Map::namespace only if defined and no name was given for this path
          name = target.namespace.to_s if name.empty? && target.namespace

          rule = Rule::Map.new(path, target, name)
        end

        if localizing?
          localized_rule.not_nil!.rules << rule
        else
          rules << rule
        end
      end

      private def path_with_duplicated_parameters?(path_for_interpolation)
        matches = path_for_interpolation.scan(INTERPOLATION_PARAMETER_RE)
        parameter_names = matches.reduce([] of String) { |acc, match| acc + match.captures }
        parameter_names.size != parameter_names.uniq.size
      end

      private def perform_reverse(name, params)
        reversed = nil

        begin
          reverser = reversers[name]
          reversed = reverser.reverse(params)
        rescue KeyError
          raise Errors::NoReverseMatch.new("'#{name}' does not match any registered route")
        end

        raise Errors::NoReverseMatch.new("'#{name}' route cannot receive #{params} as parameters") if reversed.nil?

        reversed
      end
    end
  end
end
