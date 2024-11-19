require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `localize` template tag.
      #
      # The `localize` template tag allows performing localization on values such as dates, numbers, and times
      # within templates. It can take one mandatory argument (the value to localize) and an optional `format`
      # keyword argument to specify a localization format.
      #
      # Usage examples:
      # ```
      # {% localize created_at %}
      # {% localize 100000 format: "short" %}
      # ```
      #
      # Optionally, the result of the localization can be assigned to a variable using `as` keyword:
      #
      # ```
      # {% localize created_at format: "short" as localized_date %}
      # ```
      class Localize < Base
        include CanExtractKwargs
        include CanSplitSmartly

        @assigned_to : String? = nil

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size < 2
            raise Errors::InvalidSyntax.new("Malformed localize tag: at least one argument must be provided")
          end

          @value_expression = FilterExpression.new(parts[1])

          if parts.size > 2 && parts[-2] == "as"
            @assigned_to = parts[-1]
            kwargs_parts = parts[2...-2]
          else
            kwargs_parts = parts[2..]
          end

          @kwargs = {} of String => FilterExpression
          extract_kwargs(kwargs_parts.join(' ')).each do |key, value|
            @kwargs[key] = FilterExpression.new(value)
          end
        end

        def render(context : Context) : String
          value = @value_expression.resolve(context).raw

          if format_value = @kwargs.delete("format")
            format = format_value.resolve(context).to_s
          end

          localized_value = localize_value(value, format)

          if @assigned_to.nil?
            localized_value
          else
            context[@assigned_to.not_nil!] = localized_value
            ""
          end
        end

        private def localize_value(value, format : String?) : String
          case value
          when Time, Float64, Int32, Int64
            valid_value = value.as(Float64 | Int32 | Int64 | Time)
            format.nil? ? I18n.l(valid_value) : I18n.l(valid_value, format)
          when Array(Marten::Template::Value)
            if value.size != 3
              raise Errors::UnsupportedValue.new(
                "Localization requires an Array with exactly 3 elements, but received #{value.size} elements. " +
                "Ensure the Array follows the format [year, month, day]."
              )
            end

            if !value.all? { |element| element.raw.is_a?(Int32) }
              types = value.map(&.raw.class).uniq!
              raise Errors::UnsupportedType.new(
                "Expected an Array with only Int32 elements, but found elements of types: #{types.join(", ")}. " +
                "Please ensure all elements are Int32."
              )
            end
            date_value = {value[0].raw.as(Int32), value[1].raw.as(Int32), value[2].raw.as(Int32)}
            format.nil? ? I18n.l(date_value) : I18n.l(date_value, format)
          else
            raise Errors::UnsupportedType.new(
              "The `localize` tag only supports localization of Time or numeric values, but got #{value.class}"
            )
          end
        end
      end
    end
  end
end
