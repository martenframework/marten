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

        # Allows to define callbacks that are called after a DB commit when a record is created, updated, or deleted.
        #
        # By default, the callback method will be called after record creations, updates, and deletions. It is also
        # possible to restrict the callback to certain actions by using the `on` argument as follows:
        #
        # ```
        # after_commit :do_something, on: :create # Will run only after creations
        # after_commit :do_something, on: :update # Will run only after updates
        # after_commit :do_something, on: :update # Will run only after saves (creations or updates)
        # after_commit :do_something, on: :delete # Will run only after deletions
        # ```
        #
        # The actions supported for the `on` argument are `create`, `update`, `save`, and `delete`. Note that it is also
        # possible to define that an after commit callback must run for multiple actions by using an array of actions:
        #
        # ```
        # after_commit :do_something, on: [:update, :delete]
        # ```
        macro after_commit(*names, **kwargs)
          {% on_kwarg = kwargs[:on] %}
          {% if on_kwarg.is_a?(NilLiteral) %}
            {% targetted_actions = [:create, :update, :delete] %}
          {% elsif on_kwarg.is_a?(ArrayLiteral) %}
            {% targetted_actions = on_kwarg.map(&.id.symbolize) %}
          {% else %}
            {% targetted_actions = [on_kwarg.id.symbolize] %}
          {% end %}

          {% if !targetted_actions.all? { |action| [:create, :update, :save, :delete].includes?(action) } %}
            raise "Invalid actions for after_commit callback: #{on_kwarg}"
          {% end %}

          {%
            targetted_actions.each do |action|
              names.reduce(MODEL_CALLBACKS[action][:commit]) do |array, name|
                array << name.id.stringify
                array
              end
            end
          %}
        end

        # Allows to define callbacks that are called after a DB rollback when a record is created, updated, or deleted.
        #
        # By default, the callback method will be called in the context of record creations, updates, and deletions. It
        # is also possible to restrict the callback to certain actions by using the `on` argument as follows:
        #
        # ```
        # after_rollback :do_something, on: :create # Will run only after creations
        # after_rollback :do_something, on: :update # Will run only after updates
        # after_rollback :do_something, on: :update # Will run only after saves (creations or updates)
        # after_rollback :do_something, on: :delete # Will run only after deletions
        # ```
        #
        # The actions supported for the `on` argument are `create`, `update`, `save`, and `delete`. Note that it is also
        # possible to define that an after rollback callback must run for multiple actions by using an array of actions:
        #
        # ```
        # after_rollback :do_something, on: [:update, :delete]
        # ```
        macro after_rollback(*names, **kwargs)
          {% on_kwarg = kwargs[:on] %}
          {% if on_kwarg.is_a?(NilLiteral) %}
            {% targetted_actions = [:create, :update, :delete] %}
          {% elsif on_kwarg.is_a?(ArrayLiteral) %}
            {% targetted_actions = on_kwarg.map(&.id.symbolize) %}
          {% else %}
            {% targetted_actions = [on_kwarg.id.symbolize] %}
          {% end %}

          {% if !targetted_actions.all? { |action| [:create, :update, :save, :delete].includes?(action) } %}
            raise "Invalid actions for after_rollback callback: #{on_kwarg}"
          {% end %}

          {%
            targetted_actions.each do |action|
              names.reduce(MODEL_CALLBACKS[action][:rollback]) do |array, name|
                array << name.id.stringify
                array
              end
            end
          %}
        end

        # Allows to define callbacks that are called after a DB commit when a record is created.
        macro after_create_commit(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:create][:commit]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to define callbacks that are called after a DB rollback when a record is created.
        macro after_create_rollback(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:create][:rollback]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to define callbacks that are called after a DB commit when a record is updated.
        macro after_update_commit(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:update][:commit]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to define callbacks that are called after a DB rollback when a record is updated.
        macro after_update_rollback(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:update][:rollback]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to define callbacks that are called after a DB commit when a record is created or updated.
        macro after_save_commit(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:save][:commit]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to define callbacks that are called after a DB rollback when a record is created or updated.
        macro after_save_rollback(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:save][:rollback]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to define callbacks that are called after a DB commit when a record is deleted.
        macro after_delete_commit(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:delete][:commit]) do |array, name|
              array << name.id.stringify
              array
            end
          %}
        end

        # Allows to define callbacks that are called after a DB rollback when a record is deleted.
        macro after_delete_rollback(*names)
          {%
            names.reduce(MODEL_CALLBACKS[:delete][:rollback]) do |array, name|
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
            create:     {before: [] of String, after: [] of String, commit: [] of String, rollback: [] of String},
            update:     {before: [] of String, after: [] of String, commit: [] of String, rollback: [] of String},
            save:       {before: [] of String, after: [] of String, commit: [] of String, rollback: [] of String},
            delete:     {before: [] of String, after: [] of String, commit: [] of String, rollback: [] of String},
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

            {% for callback_type in [:commit, :rollback] %}
              {% for callback_id in %i(create update save delete) %}
                {% if !MODEL_CALLBACKS[callback_id][callback_type].empty? %}
                  protected def has_after_{{ callback_id.id }}_{{ callback_type.id }}_callbacks?
                    true
                  end

                  protected def run_after_{{ callback_id.id }}_{{ callback_type.id }}_callbacks : Nil
                    super

                    {{ MODEL_CALLBACKS[callback_id][callback_type].join('\n').id }}
                  end
                {% else %}
                  protected def has_after_{{ callback_id.id }}_{{ callback_type.id }}_callbacks?
                    false
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

        protected def run_after_create_commit_callbacks
        end

        protected def run_after_update_commit_callbacks
        end

        protected def run_after_save_commit_callbacks
        end

        protected def run_after_delete_commit_callbacks
        end

        protected def run_after_create_rollback_callbacks
        end

        protected def run_after_update_rollback_callbacks
        end

        protected def run_after_save_rollback_callbacks
        end

        protected def run_after_delete_rollback_callbacks
        end

        protected def has_after_create_commit_callbacks?
          false
        end

        protected def has_after_update_commit_callbacks?
          false
        end

        protected def has_after_save_commit_callbacks?
          false
        end

        protected def has_after_delete_commit_callbacks?
          false
        end

        protected def has_after_create_rollback_callbacks?
          false
        end

        protected def has_after_update_rollback_callbacks?
          false
        end

        protected def has_after_save_rollback_callbacks?
          false
        end

        protected def has_after_delete_rollback_callbacks?
          false
        end
      end
    end
  end
end
