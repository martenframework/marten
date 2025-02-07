module Marten
  module Template
    module Filter
      # The "underscore" filter.
      #
      # The "underscore" filter allows to convert a string to its underscored version.
      class Underscore < Base
        def apply(value : Value, arg : Value? = nil) : Value
          Value.from(value.to_s.underscore)
        end
      end
    end
  end
end
