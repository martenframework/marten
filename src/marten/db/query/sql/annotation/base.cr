module Marten
  module DB
    module Query
      module SQL
        module Annotation
          abstract class Base
            getter alias_name
            getter alias_prefix
            getter field

            getter? distinct

            setter alias_prefix

            def initialize(
              @field : Field::Base,
              @alias_name : String,
              @distinct : Bool,
              @alias_prefix : String,
            )
            end

            # Extracts the annotation value from a DB result set and returns the right object corresponding to it.
            abstract def from_db_result_set(result_set : ::DB::ResultSet)

            # Returns the SQL string corresponding to the annotation.
            abstract def to_sql(with_alias : Bool = true) : String

            def clone
              self.class.new(
                @field,
                @alias_name,
                @distinct,
                @alias_prefix
              )
            end
          end
        end
      end
    end
  end
end
