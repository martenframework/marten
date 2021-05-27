module Marten
  module Template
    module Tag
      # Allows to extract keyword arguments from strings.
      #
      # This concern module allows to easily extract colon-separated keyword arguments from a given string. Each keyword
      # argument must be of the format `my_arg: my_value`.
      module CanExtractKwargs
        # Extract keyword arguments from the given source string.
        def extract_kwargs(source : String)
          kwargs = [] of Tuple(String, String)

          source.scan(KWARG_RE) do |m|
            kwargs << {m.captures[0].not_nil!, m.captures[1].not_nil!}
          end

          kwargs
        end

        private KWARG_RE = /
          (\w+)\s*\:\s*(
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
