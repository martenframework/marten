module Marten
  module DB
    abstract class Model
      module Persistence
        macro included
          extend Marten::DB::Model::Persistence::ClassMethods
        end

        module ClassMethods
          # Creates a model instance and saves it to the database if it is valid.
          #
          # The model instance is initialized using the attributes defined in the `kwargs` double splat argument.
          # Regardless of whether it is valid or not (and thus persisted to the database or not), the initialized model
          # instance is returned by this method.
          def create(**kwargs)
            object = new(**kwargs)
            object.save
            object
          end

          # Creates a model instance and saves it to the database if it is valid.
          #
          # This method provides the exact same behaviour as `create` with the ability to define a block that is
          # executed for the new object. This block can be used to directly initialize the object before it is persisted
          # to the database:
          #
          # ```
          # Post.create(title: "My blog post") do |post|
          #   post.complex_attribute = compute_complex_attribute
          # end
          # ```
          def create(**kwargs, &)
            object = new(**kwargs)
            yield object
            object.save
            object
          end

          # Creates a model instance and saves it to the database if it is valid.
          #
          # The model instance is initialized using the attributes defined in the `kwargs` double splat argument.
          # If the model instance is valid, it is persisted to the database ; otherwise a
          # `Marten::DB::Errors::InvalidRecord` exception is raised.
          def create!(**kwargs)
            object = new(**kwargs)
            object.save!
            object
          end

          # Creates a model instance and saves it to the database if it is valid.
          #
          # This method provides the exact same behaviour as `create!` with the ability to define a block that is
          # executed for the new object. This block can be used to directly initialize the object before it is persisted
          # to the database:
          #
          # ```
          # Post.create!(title: "My blog post") do |post|
          #   post.complex_attribute = compute_complex_attribute
          # end
          def create!(**kwargs, &)
            object = new(**kwargs)
            yield object
            object.save!
            object
          end
        end

        # :nodoc:
        @deleted : Bool = false

        # :nodoc:
        @new_record : Bool = true

        # Deletes the model instance.
        #
        # This methods deletes the model instance by complying to the deletion rules defined as part of the relation
        # fields if applicable (`on_delete` option on many to one or one to one fields). It returns the number of rows
        # that were deleted as part of the record deletion.
        def delete(using : Nil | String | Symbol = nil)
          deleted_count = 0

          connection = using.nil? ? self.class.connection : DB::Connection.get(using.to_s)
          connection.transaction do
            run_before_delete_callbacks

            if has_after_delete_commit_callbacks?
              connection.observe_transaction_commit(->run_after_delete_commit_callbacks)
            end

            if has_after_delete_rollback_callbacks?
              connection.observe_transaction_rollback(->run_after_delete_rollback_callbacks)
            end

            deletion = Deletion::Runner.new(
              using.nil? ? self.class.connection : DB::Connection.get(using.to_s)
            )

            deletion.add(self)
            deleted_count = deletion.execute

            @deleted = true

            run_after_delete_callbacks
          end

          deleted_count
        end

        # Returns a boolean indicating if the record was deleted or not.
        #
        # This method returns `true` if the model instance was deleted previously. Otherwise it returns `false` in any
        # other cases.
        def deleted?
          @deleted
        end

        # Returns a boolean indicating if the record doesn't exist in the database yet.
        #
        # This methods returns `true` if the model instance hasn't been saved and doesn't exist in the database yet. In
        # any other cases it returns `false`.
        def new_record?
          @new_record
        end

        # Returns a boolean indicating if the record is persisted in the database.
        #
        # This method returns `true` if the record at hand exists in the database. Otherwise (if it's a new record or if
        # it was deleted previously), the method returns `false`.
        def persisted?
          !(new_record? || deleted?)
        end

        # Reloads the model instance.
        #
        # This methods retrieves the record at the database level and updates the current model instance with the new
        # values.
        def reload
          reloaded = self.class.get!(pk: pk)

          assign_field_values(reloaded.field_values)
          reset_relation_instance_variables

          @new_record = false

          self
        end

        # Saves the model instance.
        #
        # If the model instance is new, a new record is created in the DB ; otherwise the existing record is updated.
        # This method will return `true` if the model instance is valid and was created / updated successfully.
        # Otherwise it will return `false` if the model instance validation failed.
        def save(using : Nil | String | Symbol = nil, validate : Bool = true) : Bool
          return false if validate && !valid?

          # TODO: this block should probably be executed if the record is not persisted or if changes have been made
          # to the considered record (dirty changes mechanism).
          connection = using.nil? ? self.class.connection : DB::Connection.get(using.to_s)
          connection.transaction do
            insert_or_update(connection)
            true
          end
        end

        # Saves the model instance.
        #
        # If the model instance is new, a new record is created in the DB ; otherwise the existing record is updated.
        # This method will return `true` if the model instance is valid and was created / updated successfully.
        # Otherwise it will raise a `Marten::DB::Errors::InvalidRecord` exception if the model instance validation
        # failed.
        def save!(using : Nil | String | Symbol = nil, validate : Bool = true) : Bool
          save(using: using, validate: validate) || (raise Errors::InvalidRecord.new("Record is invalid"))
        end

        # Updates the model instance.
        #
        # This method updates the passed field values and then saves the record. This method returns `true` if the model
        # instance is valid and was created / updated successfully. Otherwise it returns `false` if the model instance
        # validation fails.
        def update(**values)
          update(values)
        end

        # :ditto:
        def update(values : Hash | NamedTuple)
          set_field_values(values)
          save
        end

        # Updates the model instance.
        #
        # This method updates the passed field values and then saves the record. This method returns `true` if the model
        # instance is valid and was created / updated successfully. Otherwise it raises a
        # `Marten::DB::Errors::InvalidRecord` exception if the model instance validation fails.
        def update!(**values)
          update!(values)
        end

        # :ditto:
        def update!(values : Hash | NamedTuple)
          set_field_values(values)
          save!
        end

        protected setter new_record

        private def auto_increment_field?(pk_field : Field::Base) : Bool
          (pk_field.is_a?(Field::BigInt) || pk_field.is_a?(Field::Int)) && pk_field.auto?
        end

        private def insert_or_update(connection)
          # Prevents saving if an unsaved related object is assigned to the current model instance. This situation could
          # lead to data loss since the current model instance could be saved but not the related object.
          self.class.fields.each do |field|
            next if !field.relation?
            related_obj = get_cached_related_object(field)
            next if related_obj.nil? || related_obj.not_nil!.persisted?
            raise Errors::UnmetSaveCondition.new(
              "Save is prohibited because related object '#{field.relation_name}' is not persisted"
            )
          end

          # Notifies each field so that they have the chance to apply changes to the model instance before the actual
          # save operation.
          self.class.fields.each do |field|
            next if field.primary_key?
            field.prepare_save(self, new_record: !persisted?)
          end

          run_before_save_callbacks

          save_parents(connection)

          if has_after_save_commit_callbacks?
            connection.observe_transaction_commit(->run_after_save_commit_callbacks)
          end

          if has_after_save_rollback_callbacks?
            connection.observe_transaction_rollback(->run_after_save_rollback_callbacks)
          end

          if persisted?
            update(connection)
          else
            insert(connection)
          end

          run_after_save_callbacks
        end

        private def insert(connection)
          run_before_create_callbacks

          if has_after_create_commit_callbacks?
            connection.observe_transaction_commit(->run_after_create_commit_callbacks)
          end

          if has_after_create_rollback_callbacks?
            connection.observe_transaction_rollback(->run_after_create_rollback_callbacks)
          end

          values = local_field_db_values

          pk_field = self.class.pk_field
          if auto_increment_field?(pk_field)
            pk_field_to_fetch = pk_field.db_column!
            values.delete(pk_field_to_fetch)
          else
            pk_field_to_fetch = nil
          end

          inserted_pk = connection.insert(self.class.db_table, values, pk_field_to_fetch: pk_field_to_fetch)

          assign_field_values({pk_field.id => pk_field.from_db(inserted_pk)}) if pk.nil? && !inserted_pk.nil?
          self.new_record = false

          run_after_create_callbacks
        end

        private def insert_parent(parent_model, connection)
          values = parent_model_field_db_values(parent_model)

          parent_pk_field = parent_model.pk_field
          if auto_increment_field?(parent_pk_field)
            pk_field_to_fetch = parent_pk_field.db_column!
            values.delete(pk_field_to_fetch)
          else
            pk_field_to_fetch = nil
          end

          inserted_pk = connection.insert(parent_model.db_table, values, pk_field_to_fetch: pk_field_to_fetch)

          if parent_model.parent_models.empty?
            # If the parent model being inserted does not have concrete parent models, then this must be the first one
            # (ie. the one containing the actual primary key). In that case we must assign the value of the primary key
            # to the pointer many-to-one fields of all the underlying child models (including the current model
            # instance).
            effective_pk = inserted_pk || get_field_value(parent_model.pk_field.id)

            self.class.parent_models.each do |other_parent_model|
              assign_field_values({other_parent_model.pk_field.id => other_parent_model.pk_field.from_db(effective_pk)})
            end

            assign_field_values({self.class.pk_field.id => self.class.pk_field.from_db(effective_pk)})
          end
        end

        private def save_parents(connection)
          self.class.parent_models.reverse.each do |parent_model|
            if persisted?
              update_parent(parent_model, connection)
            else
              insert_parent(parent_model, connection)
            end
          end
        end

        private def update(connection)
          run_before_update_callbacks

          if has_after_update_commit_callbacks?
            connection.observe_transaction_commit(->run_after_update_commit_callbacks)
          end

          if has_after_update_rollback_callbacks?
            connection.observe_transaction_rollback(->run_after_update_rollback_callbacks)
          end

          values = local_field_db_values
          values.delete(self.class.pk_field.db_column!)

          connection.update(
            self.class.db_table,
            values,
            pk_column_name: self.class.pk_field.db_column!,
            pk_value: self.class.pk_field.to_db(pk)
          )

          run_after_update_callbacks
        end

        private def update_parent(parent_model, connection)
          values = parent_model_field_db_values(parent_model)
          values.delete(parent_model.pk_field.db_column!)

          connection.update(
            parent_model.db_table,
            values,
            pk_column_name: parent_model.pk_field.db_column!,
            pk_value: parent_model.pk_field.to_db(pk)
          )
        end
      end
    end
  end
end
