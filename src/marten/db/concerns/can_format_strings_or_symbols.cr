module Marten
  module DB
    # Simple module providing a convenient way to format string values to either string literals or symbols.
    module CanFormatStringsOrSymbols
      def format_string_or_symbol(value : String)
        value =~ /^[a-zA-Z_][a-zA-AZ_0-9]*$/ ? ":#{value}" : %{"#{value}"}
      end
    end
  end
end
