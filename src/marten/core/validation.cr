module Marten
  module Core
    # Provides validation to objects.
    module Validation
      @validation_context : String?

      # Returns the error set containing the errors generated during a validation.
      getter errors : ErrorSet = ErrorSet.new

      macro included
        include Marten::Core::Validation::Callbacks

        _begin_validation_methods_setup

        macro inherited
          _begin_validation_methods_setup

          macro finished
            _finish_validation_methods_setup
          end
        end

        macro finished
          _finish_validation_methods_setup
        end
      end

      # Registers validation methods.
      macro validate(*names)
        {%
          names.reduce(VALIDATION_METHODS) do |array, name|
            array << name.id.stringify
            array
          end
        %}
      end

      # :nodoc:
      macro _begin_validation_methods_setup
        # :nodoc:
        VALIDATION_METHODS = [] of String
      end

      # :nodoc:
      macro _finish_validation_methods_setup
        {% verbatim do %}
          {% if !VALIDATION_METHODS.empty? %}
            protected def run_validation_methods
              super
              {{ VALIDATION_METHODS.join("\n").id }}
            end
          {% end %}
        {% end %}
      end

      # Returns a boolean indicating whether the object is valid.
      #
      # An optional context can be specified using the `context` argument. When this option is used, additional
      # validation rules that explicitly require a specific context might run.
      def valid?(context : Nil | String | Symbol = nil)
        current_context = validation_context
        self.validation_context = context.try(&.to_s)
        @errors.clear
        perform_validation
      ensure
        self.validation_context = current_context
      end

      # Returns a boolean indicating whether the object is invalid.
      #
      # An optional context can be specified using the `context` argument. When this option is used, additional
      # validation rules that explicitly require a specific context might run.
      def invalid?(context : Nil | String | Symbol = nil)
        !valid?(context)
      end

      # Allows to run custom validations for the considered object.
      #
      # By default this method is empty and does nothing. It should be overridden in the specific class at hand in order
      # to implement custom validation logics.
      def validate
      end

      protected def run_validation_methods
      end

      private getter validation_context

      private def perform_validation
        run_before_validation_callbacks

        validate
        run_validation_methods

        return false unless errors.empty?

        run_after_validation_callbacks

        true
      end

      private def validation_context=(context)
        @validation_context = context
      end
    end
  end
end
