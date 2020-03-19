module Marten
  module Routing
    class Map
      getter rules
      getter reversers

      def self.draw
        map = new
        with map yield map
        map
      end

      def initialize
        @rules = [] of Rule::Base
        @reversers = {} of String => Reverser
      end

      def draw
        with self yield self
      end

      # Inserts a new path into the routes map.
      #
      # The target associated with the considered path must be either a view (subclass of
      # `Marten::Views::Base`) or another `Marten::Routing::Map` instance (in case of nested routes
      # maps). Each <path, target> pair must be given a name that will be used to uniquely identify
      # the route.
      def path(path : String, target : Marten::Views::Base.class | Map, name : String | Symbol)
        unless RULE_NAME_RE.match(name)
          raise Errors::InvalidRuleName.new(
            "A rule name can only contain letters, numbers, dashes or underscores"
          )
        end

        unless @rules.find { |r| r.name == name }.nil?
          raise Errors::InvalidRuleName.new("A '#{name}' route already exists")
        end

        if target.is_a?(Marten::Views::Base.class)
          rule = Rule::Path.new(path, target, name.to_s)
        else  # Nested routes map
          rule = Rule::Map.new(path, target, name.to_s)
        end

        @rules << rule

        # Inserts the reversers associated with the newly added rule to the local list of reversers
        # in order to ease later reverse operations.
        rule.reversers.each do |reverser|
          @reversers[reverser.name] = reverser
        end
      end

      # Resolves a path - identify a route matching a specific path.
      #
      # The route resolution process tries to identify which view corresponds to the considered
      # path and returns a `Marten::Routing::Match` object if a match is found. If no match is
      # found a `Marten::Routing::Errors::NoResolveMatch` exception is raised.
      def resolve(path : String) : Match
        match = @rules.each do |r|
          matched = r.resolve(path)
          break matched unless matched.nil?
        end

        raise Errors::NoResolveMatch.new if match.nil?
        match
      end

      # Reverses a URL - returns the URL corresponding to a specific route name and parameters.
      #
      # The URL lookup mechanism tries to identify the route matching the given name and tries to
      # apply any extra parameters passed in the method call. If no route is found or if the
      # arguments can't be applied to the route, a `Marten::Routing::Errors::NoReverseMatch`
      # exception is raised.
      def reverse(name : String, **kwargs) : String
        reversed = nil

        begin
          reverser = @reversers[name]
          reversed = reverser.reverse(**kwargs)
        rescue KeyError
          raise Errors::NoReverseMatch.new("'#{name}' does not match any registered route")
        end

        if reversed.nil?
          raise Errors::NoReverseMatch.new("'#{name}' route cannot receive #{kwargs} as parameters")
        end

        reversed
      end

      private RULE_NAME_RE = /^[a-zA-Z_0-9]+$/
    end
  end
end
