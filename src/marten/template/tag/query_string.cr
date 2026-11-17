require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `querystring` template tag.
      #
      # The `querystring` template tag builds a URL-encoded query string that always starts with `?`. Without
      # arguments, it starts from the query string of the current HTTP request. Keyword arguments add or replace
      # parameters. For example the following lines are valid usages of the `querystring` tag:
      #
      # ```
      # {% querystring %}
      # {% querystring color: "red", size: "S" %}
      # {% querystring color: nil %}
      # ```
      #
      # A `nil` value removes a parameter, and an array value is expanded into repeated parameters. Keyword argument
      # values can be resolved as template variables too, but they can also be defined as literal values if necessary.
      #
      # Optionally, the query string can be assigned to a specific variable using the `as` keyword:
      #
      # ```
      # {% querystring page: records.next_page_number as next_page %}
      # ```
      class QueryString < Base
        include CanExtractKwargs
        include CanSplitSmartly
        include CanEscapeValues

        @assigned_to : String? = nil

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          # Identify possible assigned variable name.
          if parts.size > 2 && parts[-2] == "as"
            @assigned_to = parts[-1]
            kwargs_parts = parts[1...-2]
          else
            kwargs_parts = parts[1..]
          end

          # Identify and extract optional query string parameters.
          @kwargs = {} of String => FilterExpression
          extract_kwargs(kwargs_parts.join(' ')).each do |key, value|
            @kwargs[key] = FilterExpression.new(value)
          end
        end

        def render(context : Context) : String
          params = ParamValues.new
          default_query_params(context).each do |key, values|
            assign_values(params, key, values)
          end

          @kwargs.each do |key, expression|
            apply_value(params, key, expression.resolve(context))
          end

          query_string = build_query_string(params)

          if @assigned_to.nil?
            escape_value(query_string, context)
          else
            context[@assigned_to.not_nil!] = query_string
            ""
          end
        end

        private alias ParamValues = Hash(String, Array(String))

        private def apply_value(params : ParamValues, key : String, value : Value) : Nil
          case raw = value.raw
          when Nil
            params.delete(key)
          when Array(Value)
            values = [] of String
            raw.each do |item|
              next if item.raw.nil?
              values << query_value_to_s(item.raw)
            end
            assign_values(params, key, values)
          when Hash(Value, Value)
            values = [] of String
            raw.each_key do |item|
              next if item.raw.nil?
              values << query_value_to_s(item.raw)
            end
            assign_values(params, key, values)
          else
            params[key] = [query_value_to_s(raw)]
          end
        end

        private def assign_values(params : ParamValues, key : String, values : Array(String)) : Nil
          if values.empty?
            params.delete(key)
          else
            params[key] = values.dup
          end
        end

        private def build_query_string(params : ParamValues) : String
          query = String.build do |io|
            builder = ::HTTP::Params::Builder.new(io)
            params.each do |key, values|
              values.each do |value|
                builder.add(key, value)
              end
            end
          end

          "?#{query}"
        end

        private def default_query_params(context : Context) : HTTP::Params::Query
          if context.has_key?("request")
            case raw = context["request"].raw
            when HTTP::Request
              return raw.query_params
            else
              raise Errors::UnsupportedType.new(
                "querystring requires the 'request' context variable to be an HTTP request " \
                "(got #{raw.class} instead)"
              )
            end
          end

          if handler = context.handler
            return handler.request.query_params
          end

          raise Errors::InvalidSyntax.new(
            "The querystring tag requires an HTTP request in the template context"
          )
        end

        private def query_value_to_s(raw) : String
          raw.to_s
        end
      end
    end
  end
end
