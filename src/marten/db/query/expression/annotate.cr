module Marten
  module DB
    module Query
      class Expression
        class Annotate
          getter annotations

          def initialize
            @annotations = [] of DB::Query::Annotation
          end

          def average(
            field : String | Symbol,
            alias_name : Nil | String | Symbol = nil,
            distinct : Bool = false,
          ) : DB::Query::Annotation
            ann = DB::Query::Annotation.average(
              field: field.to_s,
              alias_name: alias_name.try(&.to_s),
              distinct: distinct,
            )
            @annotations << ann
            ann
          end

          def count(
            field : String | Symbol,
            alias_name : Nil | String | Symbol = nil,
            distinct : Bool = false,
          ) : DB::Query::Annotation
            ann = DB::Query::Annotation.count(
              field: field.to_s,
              alias_name: alias_name.try(&.to_s),
              distinct: distinct,
            )
            @annotations << ann
            ann
          end

          def maximum(
            field : String | Symbol,
            alias_name : Nil | String | Symbol = nil,
            distinct : Bool = false,
          ) : DB::Query::Annotation
            ann = DB::Query::Annotation.maximum(
              field: field.to_s,
              alias_name: alias_name.try(&.to_s),
              distinct: distinct,
            )
            @annotations << ann
            ann
          end

          def minimum(
            field : String | Symbol,
            alias_name : Nil | String | Symbol = nil,
            distinct : Bool = false,
          ) : DB::Query::Annotation
            ann = DB::Query::Annotation.minimum(
              field: field.to_s,
              alias_name: alias_name.try(&.to_s),
              distinct: distinct,
            )
            @annotations << ann
            ann
          end

          def sum(
            field : String | Symbol,
            alias_name : Nil | String | Symbol = nil,
            distinct : Bool = false,
          ) : DB::Query::Annotation
            ann = DB::Query::Annotation.sum(
              field: field.to_s,
              alias_name: alias_name.try(&.to_s),
              distinct: distinct,
            )
            @annotations << ann
            ann
          end
        end
      end
    end
  end
end
