module Marten
  module Template
    module Filter
      # The "join" filter.
      #
      # The "join" filter converts an array into a string with elements separated by `arg`.
      class Join < Base
        def apply(value : Value, arg : Value? = nil) : Value
          # Only work on array
          return value if !value.raw.is_a?(Array)
          if arg
            Value.from(value.to_a.map(&.to_s).join(arg.to_s))
          else
            Value.from(value.to_a.map(&.to_s).join)
          end
        end
      end
    end
  end
end
