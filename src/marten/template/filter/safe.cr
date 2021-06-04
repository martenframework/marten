module Marten
  module Template
    module Filter
      # The `safe` filter.
      #
      # The `safe` filter allows to mark that a string is safe and that it should not be escaped before being inserted
      # in the final output of a rendered template.
      class Safe < Base
        def apply(value : Value, arg : Value? = nil) : Value
          Value.from(SafeString.new(value.to_s))
        end
      end
    end
  end
end
