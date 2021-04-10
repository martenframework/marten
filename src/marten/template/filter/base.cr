module Marten
  module Template
    module Filter
      # The template filter base class.
      #
      # A template filter allows to apply transformations to variables. Filters can be chained and can take an optional
      # argument.
      abstract class Base
        abstract def apply(value : Value, arg : Value? = nil) : Value
      end
    end
  end
end
