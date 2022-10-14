require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `url` template tag.
      #
      # The `url` template tag allows to perform URL lookups. It must be take at least one argument (the name of the
      # targeted handler) followed by optional keyword arguments. For example the following lines are valid usages of
      # the `url` tag:
      #
      # ```
      # {% url "my_handler" %}
      # {% url "my_other_handler" arg1: var1, arg2: var2 %}
      # ```
      #
      # URL names and parameter values can be resolved as template variables too, but they can also be defined as
      # literal values if necessary.
      #
      # Optionally, resolved URLs can be assigned to a specific variable using the `as` keyword:
      #
      # ```
      # {% url "my_other_handler" arg1: var1, arg2: var2 as my_var %}
      # ```
      class Url < Base
        include CanExtractKwargs
        include CanSplitSmartly

        @assigned_to : String? = nil

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size < 2
            raise Errors::InvalidSyntax.new("Malformed url tag: at least one argument must be provided")
          end

          @url_name_expression = FilterExpression.new(parts[1])

          # Identify possible assigned variable name.
          if parts.size > 2 && parts[-2] == "as"
            @assigned_to = parts[-1]
            kwargs_parts = parts[2...-2]
          else
            kwargs_parts = parts[2..]
          end

          # Identify and extract optional URL parameters.
          @kwargs = {} of String => FilterExpression
          extract_kwargs(kwargs_parts.join(' ')).each do |key, value|
            @kwargs[key] = FilterExpression.new(value)
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

          url = Marten.routes.reverse(url_name, url_params)

          if @assigned_to.nil?
            url
          else
            context[@assigned_to.not_nil!] = url
            ""
          end
        end
      end
    end
  end
end
