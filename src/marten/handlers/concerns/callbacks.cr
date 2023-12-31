module Marten
  module Handlers
    # Provides the ability to define handler callbacks.
    #
    # This module provides the ability to define callbacks that are executed during the lifecycle of the considered
    # handlers. They allow to intercept the incoming request and to return early HTTP responses. Three hooks are enabled
    # by the use of this module: `before_dispatch` callbacks are executed before the execution of the handler's
    # `#dispatch` method while `after_dispatch` callbacks are executed after it, and `before_render` callbacks are
    # executed before the rendering of the template.
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

      # Allows to do define callbacks that are called before executing `Marten::Handler#dispatch`.
      #
      # Those callbacks have access to the incoming `#request` object and they can return early response. If one of such
      # callbacks returns an early response, the following callbacks will be skipped, as well as the handler's
      # `#dispatch` method.
      macro before_dispatch(*names)
        {%
          names.reduce(CALLBACKS[:before_dispatch]) do |array, name|
            array << name.id.stringify
            array
          end
        %}
      end

      # Allows to do define callbacks that are called after executing `Marten::Handler#dispatch`.
      #
      # Those callbacks have access to the incoming `#request` object and they can return a custom HTTP response. If one
      # of such callbacks returns a custom HTTP response, the following callbacks will be skipped and this custom
      # response will be returned by the handler instead of the one returned by the `#dispatch` method.
      macro after_dispatch(*names)
        {%
          names.reduce(CALLBACKS[:after_dispatch]) do |array, name|
            array << name.id.stringify
            array
          end
        %}
      end

      # Allows to do define callbacks that are called before rendering templates.
      #
      # Those callbacks have access to the incoming `#request` object and they can return early response. If one of such
      # callbacks returns an early response, the following callbacks will be skipped and the response will be returned
      # by the handler directly.
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
          before_dispatch: [] of String,
          before_render:   [] of String,
          after_dispatch:  [] of String,
        }
      end

      # :nodoc:
      macro _finish_callbacks_setup
        {% verbatim do %}
          {% if !CALLBACKS[:before_dispatch].empty? %}
            protected def run_before_dispatch_callbacks : Marten::HTTP::Response | Nil
              callbacks_response = super
              return callbacks_response unless callbacks_response.nil?

              {% for callback in CALLBACKS[:before_dispatch] %}
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

          {% if !CALLBACKS[:after_dispatch].empty? %}
            protected def run_after_dispatch_callbacks : Marten::HTTP::Response | Nil
              callbacks_response = super
              return callbacks_response unless callbacks_response.nil?

              {% for callback in CALLBACKS[:after_dispatch] %}
                result = {{ callback.id }}.as?(Marten::HTTP::Response)
                return result unless result.nil?
              {% end %}
            end
          {% end %}
        {% end %}
      end

      protected def run_before_dispatch_callbacks
      end

      protected def run_before_render_callbacks
      end

      protected def run_after_dispatch_callbacks
      end
    end
  end
end
