module Marten
  module Emailing
    class Email
      # Provides the ability to define email callbacks.
      #
      # This module provides the ability to define callbacks that are executed during the lifecycle of the considered
      # emails. Three hooks are enabled by the use of this module: `before_deliver` callbacks are executed before the
      # delivery of the email method while `after_deliver` callbacks are executed after it, and `before_render`
      # callbacks are executed before the rendering of a template used to generate the content of the email.
      module Callbacks
        macro included
          _begin_callbacks_setup

          macro inherited
            _begin_callbacks_setup

            macro finished
              _finish_callbacks_setup
            end
          end

          macro finished
            _finish_callbacks_setup
          end
        end

        # Allows to do define callbacks that are called before delivering the email.
        macro before_deliver(*names)
          {%
            names.reduce(CALLBACKS[:before_deliver]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to do define callbacks that are called after delivering the email.
        macro after_deliver(*names)
          {%
            names.reduce(CALLBACKS[:after_deliver]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to do define callbacks that are called before rendering templates.
        macro before_render(*names)
          {%
            names.reduce(CALLBACKS[:before_render]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # :nodoc:
        macro _begin_callbacks_setup
          # :nodoc:
          CALLBACKS = {
            before_deliver: [] of String,
            before_render:  [] of String,
            after_deliver:  [] of String,
          }
        end

        # :nodoc:
        macro _finish_callbacks_setup
          {% verbatim do %}
            {% if !CALLBACKS[:before_deliver].empty? %}
              protected def run_before_deliver_callbacks : Marten::HTTP::Response | Nil
                callbacks_response = super
                return callbacks_response unless callbacks_response.nil?

                {% for callback in CALLBACKS[:before_deliver] %}
                  result = {{ callback.id }}.as?(Marten::HTTP::Response)
                  return result unless result.nil?
                {% end %}
              end
            {% end %}

            {% if !CALLBACKS[:before_render].empty? %}
              protected def run_before_render_callbacks : Marten::HTTP::Response | Nil
                callbacks_response = super
                return callbacks_response unless callbacks_response.nil?

                {% for callback in CALLBACKS[:before_render] %}
                  result = {{ callback.id }}.as?(Marten::HTTP::Response)
                  return result unless result.nil?
                {% end %}
              end
            {% end %}

            {% if !CALLBACKS[:after_deliver].empty? %}
              protected def run_after_deliver_callbacks : Marten::HTTP::Response | Nil
                callbacks_response = super
                return callbacks_response unless callbacks_response.nil?

                {% for callback in CALLBACKS[:after_deliver] %}
                  result = {{ callback.id }}.as?(Marten::HTTP::Response)
                  return result unless result.nil?
                {% end %}
              end
            {% end %}
          {% end %}
        end

        protected def run_before_deliver_callbacks
        end

        protected def run_before_render_callbacks
        end

        protected def run_after_deliver_callbacks
        end
      end
    end
  end
end
