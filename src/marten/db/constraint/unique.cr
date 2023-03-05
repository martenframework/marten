module Marten
  module DB
    module Constraint
      class Unique
        getter name
        getter fields

        def initialize(@name : String, @fields : Array(Field::Base))
        end

        # Returns a clone of the current unique constraint.
        def clone
          Unique.new(name: name, fields: fields)
        end
      end
    end
  end
end
