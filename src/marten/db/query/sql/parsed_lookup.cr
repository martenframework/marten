module Marten
  module DB
    module Query
      module SQL
        private struct ParsedLookup
          getter field_tokens : Array(String)
          getter transform_name : String?
          getter comparison_name : String?

          def initialize(@field_tokens, @transform_name, @comparison_name); end
        end
      end
    end
  end
end
