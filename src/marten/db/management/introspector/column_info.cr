module Marten
  module DB
    module Management
      module Introspector
        class ColumnInfo
          getter name
          getter type
          getter default

          def initialize(
            @name : String,
            @type : String,
            @nullable : Bool,
            @default : ::DB::Any?
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
