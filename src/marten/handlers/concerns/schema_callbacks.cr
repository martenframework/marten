module Marten
  module Handlers
    # Provides the ability to define schema validation callbacks.
    #
    # This module provides the ability to define callbacks that are executed before, after, after success or/and after
    # failed validation of a schema.
    # They allow to intercept the incoming request and to return early HTTP responses. TwFouro hooks
    # are enabled by the use of this module:
    # - `before_schema_validation` callbacks are executed before the validation of the schema
    # - `after_schema_validation` callbacks are executed right after the validation of the schema
    # - `after_successful_schema_validation` callbacks are executed right after the validation but
    #    only if the schema is valid
    # - `after_failed_schema_validation` callbacks are executed right after the validation but
    #    only if the schema is not valid
    module SchemaCallbacks
      macro included
        _begin_validation_callbacks_setup

        macro inherited
          _begin_validation_callbacks_setup

          macro finished
            _finish_validation_callbacks_setup
          end
        end

        macro finished
          _finish_validation_callbacks_setup
        end
      end

      # Allows to do define callbacks that are called after executing `Marten::Schema#valid?`.
      #
      # Those callbacks have access to the incoming `#request` object and they can return a custom HTTP response.
      # If one of such callbacks returns a custom HTTP response, the following callbacks will be skipped and this
      # custom response will be returned by the handler instead of the success or fail HTTP response.
      macro before_schema_validation(*names)
          {%
            names.reduce(VALIDATION_CALLBACKS[:before_validation]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

      # Allows to do define callbacks that are called after executing `Marten::Schema#valid?`.
      #
      # Those callbacks have access to the incoming `#request` object and they can return a custom HTTP response.
      # If one of such callbacks returns a custom HTTP response, the following callbacks will be skipped and this
      # custom response will be returned by the handler instead of the success or fail HTTP response.
      macro after_schema_validation(*names)
          {%
            names.reduce(VALIDATION_CALLBACKS[:after_validation]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

      # Allows to do define callbacks that are called after executing `Marten::Schema#valid?`.
      #
      # Those callbacks have access to the incoming `#request` object and they can return a custom HTTP response.
      # If one of such callbacks returns a custom HTTP response, the following callbacks will be skipped and this
      # custom response will be returned by the handler instead of the success or fail HTTP response.
      macro after_successful_schema_validation(*names)
          {%
            names.reduce(VALIDATION_CALLBACKS[:after_successful_validation]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

      # Allows to do define callbacks that are called after executing `Marten::Schema#valid?`.
      #
      # Those callbacks have access to the incoming `#request` object and they can return a custom HTTP response.
      # If one of such callbacks returns a custom HTTP response, the following callbacks will be skipped and
      # this custom response will be returned by the handler instead of the success or fail HTTP response.
      macro after_failed_schema_validation(*names)
          {%
            names.reduce(VALIDATION_CALLBACKS[:after_failed_validation]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

      # :nodoc:
      macro _begin_validation_callbacks_setup
        # :nodoc:
        VALIDATION_CALLBACKS = {
          before_validation:           [] of String,
          after_validation:            [] of String,
          after_successful_validation: [] of String,
          after_failed_validation:     [] of String,
        }
      end

      # :nodoc:
      macro _finish_validation_callbacks_setup
          {% verbatim do %}
            {% if !VALIDATION_CALLBACKS[:before_validation].empty? %}
              protected def run_before_validation_callbacks : Marten::HTTP::Response | Nil
                callbacks_response = super
                return callbacks_response unless callbacks_response.nil?

                {% for callback in VALIDATION_CALLBACKS[:before_validation] %}
                  result = {{ callback.id }}.as?(Marten::HTTP::Response)
                  return result unless result.nil?
                {% end %}
              end
            {% end %}

            {% if !VALIDATION_CALLBACKS[:after_validation].empty? %}
              protected def run_after_validation_callbacks : Marten::HTTP::Response | Nil
                callbacks_response = super
                return callbacks_response unless callbacks_response.nil?

                {% for callback in VALIDATION_CALLBACKS[:after_validation] %}
                  result = {{ callback.id }}.as?(Marten::HTTP::Response)
                  return result unless result.nil?
                {% end %}
              end
            {% end %}

            {% if !VALIDATION_CALLBACKS[:after_successful_validation].empty? %}
              protected def run_after_successful_validation_callbacks : Marten::HTTP::Response | Nil
                callbacks_response = super
                return callbacks_response unless callbacks_response.nil?

                {% for callback in VALIDATION_CALLBACKS[:after_successful_validation] %}
                  result = {{ callback.id }}.as?(Marten::HTTP::Response)
                  return result unless result.nil?
                {% end %}
              end
            {% end %}

            {% if !VALIDATION_CALLBACKS[:after_failed_validation].empty? %}
              protected def run_after_failed_validation_callbacks : Marten::HTTP::Response | Nil
                callbacks_response = super
                return callbacks_response unless callbacks_response.nil?

                {% for callback in VALIDATION_CALLBACKS[:after_failed_validation] %}
                  result = {{ callback.id }}.as?(Marten::HTTP::Response)
                  return result unless result.nil?
                {% end %}
              end
            {% end %}
          {% end %}
        end

      protected def run_before_validation_callbacks
      end

      protected def run_after_validation_callbacks
      end

      protected def run_after_successful_validation_callbacks
      end

      protected def run_after_failed_validation_callbacks
      end
    end
  end
end
