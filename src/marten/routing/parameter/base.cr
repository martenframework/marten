module Marten
  module Routing
    module Parameter
      abstract class Base
        abstract def regex : Regex
        abstract def loads(value : ::String)
        abstract def dumps(value) : Nil | ::String

        macro regex(regex)
          {% sanitized_regex = regex.is_a?(RegexLiteral) ? regex : nil %}
          {% if sanitized_regex.is_a?(NilLiteral) %}
            {% raise "Cannot use '#{regex}' as a valid parameter regex" %}
          {% end %}

          def regex : Regex
            {{ regex }}
          end
        end
      end
    end
  end
end
