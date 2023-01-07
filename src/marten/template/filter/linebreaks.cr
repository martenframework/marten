module Marten
  module Template
    module Filter
      # The `linebreaks` filter.
      #
      # The `linebreaks` filter allows to convert a string replacing all newlines with HTML line breaks (<br />).
      class LineBreaks < Base
        def apply(value : Value, arg : Value? = nil) : Value
          Value.from(value.to_s.gsub("\n", "<br />"))
        end
      end
    end
  end
end
