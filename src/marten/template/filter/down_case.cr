module Marten
  module Template
    module Filter
      # The "downcase" filter.
      #
      # The "downcase" filter allows to convert a string so that each of its character is lowercase.
      class DownCase < Base
        def apply(value : Value, arg : Value? = nil) : Value
          Value.from(value.to_s.downcase)
        end
      end
    end
  end
end
