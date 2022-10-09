module Marten
  module DB
    abstract class Model
      # Provides the ability to define model callbacks.
      #
      # This module provides the ability to define callbacks that are executed before and / or after specific model
      # record operations (ie. initialization, creation, update, save, and deletion).
      module Callbacks
        macro included
          _begin_model_callbacks_setup

          macro inherited
            _begin_model_callbacks_setup

            macro finished
              _finish_model_callbacks_setup
            end
          end

          macro finished
            _finish_model_callbacks_setup
          end
        end

        # Allows to do define callbacks that are called after initializing a model record.
        macro after_initialize(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:initialize][:after]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to do define callbacks that are called before creating a model record.
        macro before_create(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:create][:before]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to do define callbacks that are called after creating a model record.
        macro after_create(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:create][:after]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to do define callbacks that are called before updating a model record.
        macro before_update(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:update][:before]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to do define callbacks that are called after updating a model record.
        macro after_update(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:update][:after]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to do define callbacks that are called before saving a model record (creation or update).
        macro before_save(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:save][:before]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to do define callbacks that are called after saving a model record (creation or update).
        macro after_save(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:save][:after]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to do define callbacks that are called before deleting a model record.
        macro before_delete(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:delete][:before]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to do define callbacks that are called after deleting a model record.
        macro after_delete(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:delete][:after]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # :nodoc:
        macro _begin_model_callbacks_setup
          # :nodoc:
          MODEL_CALLBACKS = {
            initialize: {after: [] of String},
            create:     {before: [] of String, after: [] of String},
            update:     {before: [] of String, after: [] of String},
            save:       {before: [] of String, after: [] of String},
            delete:     {before: [] of String, after: [] of String},
          }
        end

        # :nodoc:
        macro _finish_model_callbacks_setup
          {% verbatim do %}
            {% if !MODEL_CALLBACKS[:initialize][:after].empty? %}
              protected def run_after_initialize_callbacks : Nil
                super

                {{ MODEL_CALLBACKS[:initialize][:after].join('\n').id }}
              end
            {% end %}

            {% for callback_type in [:before, :after] %}
              {% for callback_id in %i(create update save delete) %}
                {% if !MODEL_CALLBACKS[callback_id][callback_type].empty? %}
                  protected def run_{{ callback_type.id }}_{{ callback_id.id }}_callbacks : Nil
                    super

                    {{ MODEL_CALLBACKS[callback_id][callback_type].join('\n').id }}
                  end
                {% end %}
              {% end %}
            {% end %}
          {% end %}
        end

        protected def run_after_initialize_callbacks
        end

        protected def run_before_create_callbacks
        end

        protected def run_after_create_callbacks
        end

        protected def run_before_update_callbacks
        end

        protected def run_after_update_callbacks
        end

        protected def run_before_save_callbacks
        end

        protected def run_after_save_callbacks
        end

        protected def run_before_delete_callbacks
        end

        protected def run_after_delete_callbacks
        end
      end
    end
  end
end
