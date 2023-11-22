module Marten
  module Template
    module Filter
      # The `escape` filter.
      #
      # The `escape` filter replaces special characters (namely &, <, >, " and ')
      # in the template variable with their corresponding HTML entities.
      class Escape < Base
        def apply(value : Value, arg : Value? = nil) : Value
          Value.from(SafeString.new(HTML.escape(value.to_s)))
        end
      end
    end
  end
end
