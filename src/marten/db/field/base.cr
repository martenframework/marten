module Marten
  module DB
    module Field
      abstract class Base
        @primary_key : Bool
        @blank : Bool
        @null : Bool
        @name : ::String?

        getter id

        def initialize(
          @id : ::String,
          @primary_key = false,
          @blank = false,
          @null = false,
          @name = nil
        )
        end

        abstract def from_db_result_set(result_set : ::DB::ResultSet)
      end
    end
  end
end
