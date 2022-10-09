module Marten
  module Core
    module Validation
      # Provides the ability to define validation callbacks.
      #
      # This module provides the ability to define callbacks that are executed before and / or after running validation
      # rules for the validated objects. Two hooks are enabled by the use of this module: `before_validation` callbacks
      # are executed before running validation rules while `after_validation` callbacks are executed after running them.
      module Callbacks
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

        # Allows to do define callbacks that are called before running the registered validation rules.
        #
        # Either one or multiple validation methods can be specified:
        #
        # ```
        # class MyClass
        #   include Marten::Core::Validation
        #
        #   before_validation(:callback_1)
        #   before_validation(:callback_2, :callback_3)
        # end
        # ```
        macro before_validation(*names)
          {%
            names.reduce(VALIDATION_CALLBACKS[:before]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to do define callbacks that are called after running the registered validation rules.
        #
        # Either one or multiple validation methods can be specified:
        #
        # ```
        # class MyClass
        #   include Marten::Core::Validation
        #
        #   after_validation(:callback_1)
        #   after_validation(:callback_2, :callback_3)
        # end
        # ```
        macro after_validation(*names)
          {%
            names.reduce(VALIDATION_CALLBACKS[:after]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # :nodoc:
        macro _begin_validation_callbacks_setup
          # :nodoc:
          VALIDATION_CALLBACKS = {
            before: [] of String,
            after:  [] of String,
          }
        end

        # :nodoc:
        macro _finish_validation_callbacks_setup
          {% verbatim do %}
            {% if !VALIDATION_CALLBACKS[:before].empty? %}
              protected def run_before_validation_callbacks : Nil
                super

                {% for callback in VALIDATION_CALLBACKS[:before] %}
                  {{ callback.id }}
                {% end %}
              end
            {% end %}

            {% if !VALIDATION_CALLBACKS[:after].empty? %}
              protected def run_after_validation_callbacks : Nil
                super

                {% for callback in VALIDATION_CALLBACKS[:after] %}
                  {{ callback.id }}
                {% end %}
              end
            {% end %}
          {% end %}
        end

        protected def run_before_validation_callbacks
        end

        protected def run_after_validation_callbacks
        end
      end
    end
  end
end
