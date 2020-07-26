module Marten
  module DB
    abstract class Model
      # Provides validation to model instances.
      module Validation
        macro included
          include Core::Validation

          private def perform_validation
            self.class.fields.each do |field|
              field.perform_validation(self)
            end

            super
          end
        end
      end
    end
  end
end
