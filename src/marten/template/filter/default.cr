module Marten
  module Template
    module Filter
      # The "default" filter.
      #
      # The "default" filter allows to fallback to a specific value if the left side of the filter expression is not
      # truthy. A filter argument is mandatory. It should be noted that empty strings are considered and will be
      # returned by this filter.
      class Default < Base
        def apply(value : Value, arg : Value? = nil) : Value
          raise Errors::InvalidSyntax.new("The 'default' filter requires one argument") if arg.nil?
          value.truthy? ? value : arg.not_nil!
        end
      end
    end
  end
end
