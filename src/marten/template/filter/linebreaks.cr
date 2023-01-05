module Marten
  module Template
    module Filter
      # The `linebreaks` filter.
      #
      # The `linebreaks` filter allows to modify a string so that the first letter is converted to uppercase and all the
      # subsequent letters are converted to lowercase.
      class LineBreaks < Base
        def apply(value : Value, arg : Value? = nil) : Value
          Value.from(value.to_s.gsub("\n", "<br />"))
        end
      end
    end
  end
end
