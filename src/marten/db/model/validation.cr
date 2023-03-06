module Marten
  module DB
    abstract class Model
      # Provides validation to model instances.
      module Validation
        macro included
          include Core::Validation

          validate :_marten_validate_fields

          private def _marten_validate_fields
            self.class.fields.each do |field|
              field.perform_validation(self)
            end
          end
        end
      end
    end
  end
end
