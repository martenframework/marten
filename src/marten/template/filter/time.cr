module Marten
  module Template
    module Filter
      # The "time" filter.
      #
      # The "time" filter allows to output the string representation of a time variable. It requires the specification
      # of a filter argument, which is the format string used to format the time (whose available directives are part of
      # `Time::Format`).
      class Time < Base
        def apply(value : Value, arg : Value? = nil) : Value
          if !value.raw.is_a?(::Time)
            raise Errors::UnsupportedType.new(
              "The time filter can only be used on time objects, #{value.raw.class} given"
            )
          else
            time = value.raw.as(::Time)
            Value.from(arg.nil? ? time.to_s : time.to_s(arg.to_s))
          end
        end
      end
    end
  end
end
