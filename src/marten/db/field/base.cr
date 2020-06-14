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
      end
    end
  end
end
