module Marten
  module Template
    module Filter
      # The "split" filter.
      #
      # The "split" filter converts string elements separated by `arg` into an array.
      class Split < Base
        def apply(value : Value, arg : Value? = nil) : Value
          if arg
            Value.from(value.to_s.split(arg.to_s))
          else
            Value.from(value.to_s.split)
          end
        end
      end
    end
  end
end
