module Marten
  module DB
    abstract class Model
      # Provides validation to model instances.
      module Validation
        macro included
          include Core::Validation
        end
      end
    end
  end
end
