require "./query"

module Marten
  module DB
    module Query
      module SQL
        class EmptyQuery(Model) < Query(Model)
          def count(field : String | Symbol | Nil = nil)
            0_i64
          end

          def execute : Array(Model)
            Array(Model).new
          end

          def exists? : Bool
            false
          end

          def raw_delete
            0_i64
          end

          def update_with(values : Hash(String | Symbol, Field::Any | DB::Model))
            0_i64
          end

          def update_with(values : Hash(String | Symbol, Field::Any | DB::Model | EnumType)) forall EnumType
            {% unless EnumType <= ::Enum %}
              {% raise "EmptyQuery#update_with only accepts field values, model instances, and enum values" %}
            {% end %}

            0_i64
          end

          # :nodoc:
          def internal_update_with(values : Hash(String, V)) forall V
            0_i64
          end
        end
      end
    end
  end
end
