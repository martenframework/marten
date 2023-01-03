module Marten
  module Template
    module Tag
      # Allows to split expressions by respecting literal values.
      #
      # This module provides the ability to split string contents by respecting the presence of single-quoted or
      # double-quoted expressions (which can themselves contain spaces):
      #
      # ```
      # Tag.split_smartly("This is a 'simple test'")   # => ["This", "is", "a", "'simple test'"]
      # Tag.split_smartly("This is a \"simple test\"") # => ["This", "is", "a", "\"simple test/""]
      # ```
      module CanSplitSmartly
        # Split a string expression and returns an array of strings.
        def split_smartly(expression : String) : Array(String)
          expression.scan(SPLIT_RE).compact_map(&.captures.first)
        end

        private SPLIT_RE = /
          (
            (?:
              [^\s'"]*
              (?:
                (?:"(?:[^"\\]|\\.)*" | '(?:[^'\\]|\\.)*')
                [^\s'"]*
              )+
            )
            | \S+
          )
        /x
      end
    end
  end
end
