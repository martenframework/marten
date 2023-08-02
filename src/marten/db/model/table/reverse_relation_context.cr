module Marten
  module DB
    abstract class Model
      module Table
        # Context for a reverse relation.
        #
        # A reverse relation context is used to provide a mapping between a reverse relation and the model where the
        # reverse relations originates from.
        class ReverseRelationContext
          getter model
          getter reverse_relation

          def initialize(@reverse_relation : ReverseRelation, @model : Model.class)
          end
        end
      end
    end
  end
end
