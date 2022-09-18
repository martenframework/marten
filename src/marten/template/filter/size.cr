module Marten
  module Template
    module Filter
      # The `size` filter.
      #
      # The `size` filter allows to output the size of a string or enumerable.
      class Size < Base
        def apply(value : Value, arg : Value? = nil) : Value
          case object = value.raw
          when Enumerable, String
            Value.from(object.size)
          else
            raise Errors::UnsupportedType.new("#{object.class} objects don't have a size")
          end
        end
      end
    end
  end
end
