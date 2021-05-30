module Marten
  module Template
    module Filter
      # The `capitalize` filter.
      #
      # The `capitalize` filter allows to modify a string so that the first letter is converted to uppercase and all the
      # subsequent letters are converted to lowercase.
      class Capitalize < Base
        def apply(value : Value, arg : Value? = nil) : Value
          Value.from(value.to_s.capitalize)
        end
      end
    end
  end
end
