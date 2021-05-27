module Marten
  module Template
    module Tag
      # Allows to extract assignments from strings.
      #
      # This concern module allows to easily extract comma-separated assignments from a given string. Each assignment
      # must be of the format `my_var = my_value`.
      module CanExtractAssignments
        # Extract assignments from the given source string.
        def extract_assignments(source : String)
          assignments = [] of Tuple(String, String)

          source.scan(ASSIGNMENT_RE) do |m|
            assignments << {m.captures[0].not_nil!, m.captures[1].not_nil!}
          end

          assignments
        end

        private ASSIGNMENT_RE = /
          (\w+)\s*\=\s*(
            (?:
              [^\s'",]*
              (?:
                (?:"(?:[^"\\]|\\.)*" | '(?:[^'\\]|\\.)*')
                [^\s'",]*
              )+
            )
            | [^,]+
          )\s*,?
        /x
      end
    end
  end
end
