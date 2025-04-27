module Marten
  module Handlers
    # Provides the ability to define exception handlers.
    #
    # This module provides the ability to define exception handlers that are executed when an exception is raised during
    # the execution of the handler's `#dispatch` method. These handlers can be defined by using the `#rescue_from`
    # macro, which accepts one or more exception classes and an exception handler that can be specified by a trailing
    # `:with` option containing the name of a method to invoke or a block containing the exception handling logic.
    #
    # For example:
    #
    # ```
    # class ProfileHandler < Marten::Handlers::Template
    #   include RequireSignedInUser
    #
    #   template_name "auth/profile.html"
    #
    #   rescue_from Auth::UnauthorizedUser, with: :handle_unauthorized_user
    #
    #   rescue_from OtherError do
    #     redirect reverse("home")
    #   end
    #
    #   private def handle_unauthorized_user
    #     head :forbidden
    #   end
    # end
    # ```
    #
    # Exception handlers can be inherited from parent classes. They are searched bottom-up in the inheritance hierarchy.
    module ExceptionHandling
      macro included
        _begin_exception_handlers_setup

        macro inherited
          _begin_exception_handlers_setup

          macro finished
            _finish_exception_handlers_setup
          end
        end

        macro finished
          _finish_exception_handlers_setup
        end
      end

      # Allows to define an exception handler for a specific exception.
      #
      # The `rescue_from` macro accepts one or more exception classes and an exception handler that can be specified by
      # a trailing `:with` option containing the name of a method to invoke or a block containing the exception handling
      # logic.
      #
      # For example:
      #
      # ```
      # rescue_from Auth::UnauthorizedUser, with: :handle_unauthorized_user
      #
      # rescue_from OtherError do
      #   redirect reverse("home")
      # end
      # ```
      macro rescue_from(*exception_klasses, **kwargs, &block)
        {% if exception_klasses.size < 1 %}
          {% raise "At least one exception class must be provided to the `rescue_from` macro" %}
        {% end %}

        {% name = kwargs[:with] %}

        {% if !name && !block %}
          {% raise "A method name or a block must be provided to the `rescue_from` macro" %}
        {% elsif name && block %}
          {% raise "Only a method name or a block must be provided to the `rescue_from` macro" %}
        {% end %}

        {% for exception_klass in exception_klasses %}
          {% klass = exception_klass.resolve %}
          {%
            EXCEPTION_HANDLERS[klass.name] = {method_name: name, block: block}
          %}
        {% end %}
      end

      # :nodoc:
      macro _begin_exception_handlers_setup
        # :nodoc:
        EXCEPTION_HANDLERS = {} of String => String
      end

      # :nodoc:
      macro _finish_exception_handlers_setup
        {% if !EXCEPTION_HANDLERS.empty? %}
          protected def run_exception_handlers(error : Exception) : Tuple(Bool, Marten::HTTP::Response | Nil)
            already_handled, response = super
            return already_handled, response if already_handled

            {% for exception_klass, handling_configuration in EXCEPTION_HANDLERS %}
              if error.is_a?({{ exception_klass }})
                {% if handling_configuration[:method_name] %}
                  return {true, {{ handling_configuration[:method_name].id }}.as?(Marten::HTTP::Response)}
                {% else %}
                  result = begin
                    {{ handling_configuration[:block].body }}
                  end

                  return {true, result.as?(Marten::HTTP::Response)}
                {% end %}
              end
            {% end %}

            {false, nil}
          end
        {% end %}
      end

      protected def handle_exception(exception : Exception) : Marten::HTTP::Response | Nil
        run_exception_handlers(exception).last
      end

      protected def run_exception_handlers(exception : Exception) : Tuple(Bool, Marten::HTTP::Response | Nil)
        {false, nil}
      end
    end
  end
end
