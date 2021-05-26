require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `translate` template tag.
      #
      # The `translate` template tag allows to perform translation lookups by using the I18n configuration of the
      # project. It must take at least one argument (the translation key) followed by keyword arguments. For example the
      # following lines are valid usages of the `translate` tag:
      #
      # ```
      # {% translate "simple.translation" %}
      # {% translate "simple.interpolation" value: 'test' %}
      # ```
      #
      # Translation keys and parameter values can be resolved as template variables too, but they can also be defined as
      # literal values if necessary.
      #
      # Optionally, resolved translations can be assigned to a specific variable using the `as` keyword:
      #
      # ```
      # {% translate "simple.interpolation" value: 'test' as my_var %}
      # ```
      class Translate < Base
        include CanExtractKwargs
        include CanSplitSmartly

        @assigned_to : String? = nil

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size < 2
            raise Errors::InvalidSyntax.new("Malformed translate tag: at least one argument must be provided")
          end

          @lookup_key_expression = FilterExpression.new(parts[1])

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
          lookup_key = @lookup_key_expression.resolve(context).to_s

          lookup_params = {} of String => Value::Raw
          @kwargs.each do |param_name, param_expression|
            lookup_params[param_name] = param_expression.resolve(context).raw
          end

          count = lookup_params.delete("count")
          if !count.is_a?(Float64 | Int32 | Int64 | Nil)
            raise Errors::UnsupportedType.new("#{count.class} objects cannot be used for translation count parameters")
          end

          translation = I18n.t(lookup_key, lookup_params, count: count.as(Float64 | Int32 | Int64 | Nil))

          if @assigned_to.nil?
            translation
          else
            context[@assigned_to.not_nil!] = translation
            ""
          end
        end
      end
    end
  end
end
