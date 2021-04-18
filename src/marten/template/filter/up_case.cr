module Marten
  module Template
    module Filter
      # The "upcase" filter.
      #
      # The "upcase" filter allows to convert a string so that each of its character is uppercase.
      class UpCase < Base
        def apply(value : Value, arg : Value? = nil) : Value
          Value.from(value.to_s.upcase)
        end
      end
    end
  end
end
