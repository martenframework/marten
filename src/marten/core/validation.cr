module Marten
  module Core
    # Provides validation to objects.
    module Validation
      @validation_context : Symbol?

      # Returns the error set containing the errors generated during a validation.
      getter errors : ErrorSet = ErrorSet.new

      # Returns a boolean indicating whether the object is valid.
      def valid?(context : Nil | Symbol = nil)
        current_context = validation_context
        self.validation_context = context
        @errors.clear
        perform_validation
      ensure
        self.validation_context = current_context
      end

      # Returns a boolean indicating whether the object is invalid.
      def invalid?
        !valid?
      end

      # Allows to run custom validations for the considered object.
      #
      # By default this method is empty and does nothing. It should be overridden in the specific class at hand in order
      # to implement custom validation logics.
      def validate
      end

      private getter validation_context

      private def perform_validation
        validate
        errors.empty?
      end

      private def validation_context=(context)
        @validation_context = context
      end
    end
  end
end
