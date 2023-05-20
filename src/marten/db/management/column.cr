require "./column/concerns/**"

require "./column/base"
require "./column/big_int"
require "./column/bool"
require "./column/date"
require "./column/date_time"
require "./column/float"
require "./column/int"
require "./column/json"
require "./column/string"
require "./column/text"
require "./column/uuid"

require "./column/reference"

module Marten
  module DB
    module Management
      module Column
        annotation Registration
        end

        @@registry = {} of ::String => Base.class

        def self.registry
          @@registry
        end

        macro register(id, column_klass)
          {% klass = column_klass.resolve %}

          @[Marten::DB::Management::Column::Registration(id: {{ id }})]
          class ::{{ klass.id }}; end
          add_column_to_registry({{ id }}, {{ klass }})
        end

        register "big_int", BigInt
        register "bool", Bool
        register "date", Date
        register "date_time", DateTime
        register "float", Float
        register "reference", Reference
        register "int", Int
        register "json", JSON
        register "string", String
        register "text", Text
        register "uuid", UUID

        protected def self.add_column_to_registry(id : ::String | Symbol, column_klass : Base.class)
          @@registry[id.to_s] = column_klass
        end
      end
    end
  end
end
