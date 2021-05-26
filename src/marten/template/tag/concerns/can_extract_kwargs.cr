module Marten
  module Template
    module Tag
      # Allows to extract keyword arguments from strings.
      module CanExtractKwargs
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
            | [\w\.]+
          )\s*,?
        /x
      end
    end
  end
end
