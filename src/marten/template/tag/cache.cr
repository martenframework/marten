require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `cache` template tag.
      #
      # The `cache` template tag allows to cache the content of a template fragment (enclosed within the
      # `{% cache %}...{% endcache %}` tags) for a specific duration.
      #
      # At least a cache key and and a cache expiry (expressed in seconds) must be specified when using this tag:
      #
      # ```
      # {% cache "mykey" 3600 %}
      #   Cached content!
      # {% endcache %}
      # ```
      #
      # It should be noted that the `cache` template tag also supports specifying additional "vary on" arguments that
      # allow to invalidate the cache based on the value of other template variables:
      #
      # ```
      # {% cache "mykey" 3600 current_locale user.id %}
      #   Cached content!
      # {% endcache %}
      # ```
      class Cache < Base
        include CanSplitSmartly

        @expiry_expression : FilterExpression
        @inner_nodes : NodeSet
        @name_expression : FilterExpression
        @vary_on_expressions : Array(FilterExpression)

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size < 3
            raise Errors::InvalidSyntax.new("Malformed cache tag: at least two arguments must be provided")
          end

          @name_expression = FilterExpression.new(parts[1])
          @expiry_expression = FilterExpression.new(parts[2])
          @vary_on_expressions = parts[2..].map { |p| FilterExpression.new(p) }

          # Retrieves the inner nodes up to the endcache tag.
          @inner_nodes = parser.parse(up_to: {"endcache"})
          parser.shift_token
        end

        def render(context : Context) : String
          name = @name_expression.resolve(context).to_s
          vary_on = @vary_on_expressions.map(&.resolve(context).to_s.as(String))

          raw_expiry = @expiry_expression.resolve(context).to_s

          begin
            expiry = Time::Span.new(seconds: raw_expiry.to_i, nanoseconds: 0)
          rescue ArgumentError
            raise Errors::InvalidSyntax.new(
              "Invalid cache timeout value: got a non-integer value ('#{raw_expiry}')"
            )
          end

          key = fragment_key(name, vary_on)

          Marten.cache.fetch(key, expires_in: expiry) { @inner_nodes.render(context) }
        end

        private def fragment_key(name : String, vary_on : Array(String)) : String
          digest = Digest::MD5.new

          vary_on.each do |v|
            digest.update(v)
          end

          String.build do |s|
            s << "template.cache."
            s << name
            s << '.'
            s << digest.final.hexstring
          end
        end
      end
    end
  end
end
