require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `local_time` template tag.
      #
      # The `local_time` template tag allows to output the string representation of the local time. It must be take one
      # argument (the pattern used to output the time). For example the following lines are valid usages of the
      # `local_time` tag:
      #
      # ```
      # {% local_time "%Y" %}
      # {% local_time "%Y-%m-%d %H:%M:%S %:z" %}
      # ```
      #
      # Optionally, the output of this tag can be assigned to a specific variable using the `as` keyword:
      #
      # ```
      # {% local_time "%Y" as current_year %}
      # ```
      class LocalTime < Base
        include CanSplitSmartly

        @assigned_to : String? = nil

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size < 2
            raise Errors::InvalidSyntax.new("Malformed local_time tag: one argument must be provided")
          end

          @pattern_expression = FilterExpression.new(parts[1])

          # Identify possible assigned variable name.
          if parts.size > 2 && parts[-2] == "as"
            @assigned_to = parts[-1]
          elsif parts.size > 2
            raise Errors::InvalidSyntax.new("Malformed local_time tag: only one argument must be provided")
          end
        end

        def render(context : Context) : String
          time_pattern = @pattern_expression.resolve(context).to_s

          local_time = Time.local(Marten.settings.time_zone).to_s(time_pattern)

          if @assigned_to.nil?
            local_time
          else
            context[@assigned_to.not_nil!] = local_time
            ""
          end
        end
      end
    end
  end
end
