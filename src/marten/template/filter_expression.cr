module Marten
  module Template
    # Represents a template filter expression.
    #
    # A filter expression will resolve an expression such as "foo.bar|filter1|filter2", which could contain a variable
    # (whose specific attributes are accessed) to which filters are optionally applied.
    class FilterExpression
      def initialize(raw_expression : String)
        # Parse the raw expression and try to extract both the variable expression (literal or not) and the filters
        # (with optional arguments) that are successively applied to it.
        @filters_and_args = [] of Tuple(Filter::Base, Variable?)
        last_match_end = 0
        raw_variable = nil

        raw_expression.scan(FILTER_RE).each do |match|
          match_beginning = match.begin
          if last_match_end != match_beginning
            raise Errors::InvalidSyntax.new(
              "Filter expression contains characters that cannot be parsed properly: #{raw_expression}"
            )
          end

          if raw_variable.nil?
            match_variable = match.named_captures["variable"]
            if match_variable.nil? || match_variable.try(&.empty?)
              raise Errors::InvalidSyntax.new("Filter expression does not contain any variable: #{raw_expression}")
            end

            raw_variable = match_variable
          else
            filter_name = match.named_captures["filter_name"]
            filter_arg = match.named_captures["filter_arg"]
            @filters_and_args << {Filter.get(filter_name.to_s), filter_arg.nil? ? nil : Variable.new(filter_arg)}
          end

          last_match_end = match.end
        end

        if last_match_end != raw_expression.size
          raise Errors::InvalidSyntax.new(
            "Filter expression ends with characters that cannot be parsed properly: #{raw_expression}"
          )
        end

        @variable = Variable.new(raw_variable.not_nil!)
      end

      # Resolves the filter expression for a given context.
      def resolve(context : Context)
        result = @variable.resolve(context)

        @filters_and_args.each do |filter, arg|
          result = filter.apply(result, arg.nil? ? nil : arg.resolve(context))
        end

        result
      end

      private VARIABLE_RE = /([\w\.\?]+|[-+\.]?\d[\d\.e]*)|(?:"[^"\\]*(?:\\.[^"\\]*)*"|'[^'\\]*(?:\\.[^'\\]*)*')/
      private FILTER_RE   = /
        ^(?P<variable>#{VARIABLE_RE})|
        (?:\s*\|\s*
          (?P<filter_name>\w+)
          (?:\s*\:\s*
            (?:
              (?P<filter_arg>#{VARIABLE_RE})
            )
          )?
        )
      /x
    end
  end
end
