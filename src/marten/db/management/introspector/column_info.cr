module Marten
  module DB
    module Management
      module Introspector
        class ColumnInfo
          getter name
          getter type
          getter default
          getter character_maximum_length

          def initialize(
            @name : String,
            @type : String,
            @nullable : Bool,
            @default : ::DB::Any?,
            @character_maximum_length : Int32 | Int64 | Nil = nil
          )
          end

          def nullable?
            @nullable
          end
        end
      end
    end
  end
end
