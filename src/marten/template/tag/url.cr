require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `url` template tag.
      #
      # The `url` template tag allows to perform URL lookups. It must be take at least one argument (the name of the
      # targeted view) followed by optional keyword arguments. For example the following lines are valid usages of the
      # `url` tag:
      #
      # ```
      # {% url "my_view" %}
      # {% url "my_other_view" arg1: var1, arg2: var2 %}
      # ```
      #
      # URL names and parameter values can be resolved as template variables too, but they can also be defined as
      # literal values if necessary.
      class Url < Base
        include CanSplitSmartly

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size < 2
            raise Errors::InvalidSyntax.new("Malformed url tag: at least one argument must be provided")
          end

          @url_name_expression = FilterExpression.new(parts[1])

          # Identify and extract optional URL parameters.
          @kwargs = {} of String => FilterExpression
          parts[2..].join(' ').scan(KWARG_RE) do |m|
            @kwargs[m.captures[0].not_nil!] = FilterExpression.new(m.captures[1].not_nil!)
          end
        end

        def render(context : Context) : String
          url_name = @url_name_expression.resolve(context).to_s

          url_params = {} of String => Routing::Parameter::Types
          @kwargs.each do |param_name, param_expression|
            raw_param_value = param_expression.resolve(context).raw

            # Ensure that the raw param value can be used as an URL parameter.
            unless raw_param_value.is_a?(Routing::Parameter::Types)
              raise Errors::UnsupportedType.new("#{raw_param_value.class} objects cannot be used as URL parameters")
            end

            url_params[param_name] = raw_param_value
          end

          Marten.routes.reverse(url_name, url_params)
        end

        private KWARG_RE = /
          (\w+)\s*\:\s*(
            (?:
              [^\s'"]*
              (?:
                (?:"(?:[^"\\]|\\.)*" | '(?:[^'\\]|\\.)*')
                [^\s'"]*
              )+
            )
            | \w+
          )\s*,?
        /x
      end
    end
  end
end
