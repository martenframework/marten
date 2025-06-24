module Marten
  module DB
    module Query
      class Expression
        class Annotate
          getter annotations

          def initialize
            @annotations = [] of DB::Query::Annotation
          end

          def average(field : String | Symbol, alias_name : Nil | String | Symbol = nil, distinct : Bool = false) : Nil
            @annotations << DB::Query::Annotation.average(
              field: field.to_s,
              alias_name: alias_name.try(&.to_s),
              distinct: distinct,
            )
          end

          def count(field : String | Symbol, alias_name : Nil | String | Symbol = nil, distinct : Bool = false) : Nil
            @annotations << DB::Query::Annotation.count(
              field: field.to_s,
              alias_name: alias_name.try(&.to_s),
              distinct: distinct,
            )
          end

          def maximum(field : String | Symbol, alias_name : Nil | String | Symbol = nil, distinct : Bool = false) : Nil
            @annotations << DB::Query::Annotation.maximum(
              field: field.to_s,
              alias_name: alias_name.try(&.to_s),
              distinct: distinct,
            )
          end

          def minimum(field : String | Symbol, alias_name : Nil | String | Symbol = nil, distinct : Bool = false) : Nil
            @annotations << DB::Query::Annotation.minimum(
              field: field.to_s,
              alias_name: alias_name.try(&.to_s),
              distinct: distinct,
            )
          end

          def sum(field : String | Symbol, alias_name : Nil | String | Symbol = nil, distinct : Bool = false) : Nil
            @annotations << DB::Query::Annotation.sum(
              field: field.to_s,
              alias_name: alias_name.try(&.to_s),
              distinct: distinct,
            )
          end
        end
      end
    end
  end
end
