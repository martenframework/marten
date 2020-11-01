module Marten
  module Core
    # Provides validation to objects.
    module Validation
      annotation Method
      end

      @validation_context : Symbol?

      # Returns the error set containing the errors generated during a validation.
      getter errors : ErrorSet = ErrorSet.new

      macro validate(method)
        {% if !(method.is_a?(StringLiteral) || method.is_a?(SymbolLiteral)) ||
                !(method.id =~ /^[a-zA-Z_][a-zA-AZ_0-9]*$/) %}
          {% raise "Cannot use '#{method}' as a validation method" %}
        {% end %}

        @[Marten::Core::Validation::Method(name: {{ method }})]
        class ::{{ @type }}
        end
      end

      macro setup_validation
        macro included
          setup_validation
        end

        macro inherited
          setup_validation
        end
      end

      macro included
        setup_validation
      end

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
        run_validation_methods
        errors.empty?
      end

      private def run_validation_methods
        {% begin %}
          {% for ancestor_klass in @type.ancestors %}
            {% for ann, idx in ancestor_klass.annotations(Marten::Core::Validation::Method) %}
              {% if ann %}{{ ann[:name].id }}{% end %}
            {% end %}
          {% end %}
          {% for ann, idx in @type.annotations(Marten::Core::Validation::Method) %}
            {% if ann %}{{ ann[:name].id }}{% end %}
          {% end %}
        {% end %}
      end

      private def validation_context=(context)
        @validation_context = context
      end
    end
  end
end
