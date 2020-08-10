module Marten
  module DB
    abstract class Model
      module Persistence
        # :nodoc:
        @destroyed : Bool = false

        # :nodoc:
        @new_record : Bool = true

        # Saves the model instance.
        #
        # If the model instance is new, a new record is created in the DB ; otherwise the existing record is updated.
        # This method will return `true` if the model instance is valid and was created / updated successfully.
        # Otherwise it will return `false` if the model instance validation failed.
        def save : Bool
          if valid? && !persisted?
            self.class.connection.transaction do
              insert_or_update
              true
            end
          else
            false
          end
        end

        # Returns a boolean indicating if the record doesn't exist in the database yet.
        #
        # This methods returns `true` if the model instance hasn't been saved and doesn't exist in the database yet. In
        # any other cases it returns `false`.
        def new_record?
          @new_record
        end

        # Returns a boolean indicating if the record was destroyed or not.
        #
        # This method returns `true` if the model instance was destroyed previously. Other it returns `false` in any
        # other cases.
        def destroyed?
          @destroyed
        end

        # Returns a boolean indicating if the record is peristed in the database.
        #
        # This method returns `true` if the record at hand exists in the database. Otherwise (if it's a new record or if
        # it was destroyed previously), the method returns `false`.
        def persisted?
          !(new_record? || destroyed?)
        end

        protected setter new_record

        private def insert_or_update
          if persisted?
            raise NotImplementedError.new("Model records update not implemented yet")
          else
            insert
          end
        end

        private def insert
          values = field_db_values

          if self.class.pk_field.is_a?(Field::AutoTypes)
            pk_field_to_fetch = self.class.pk_field.id
            values.delete(pk_field_to_fetch)
          else
            pk_field_to_fetch = nil
          end

          self.class.fields.each do |field|
            next if field.primary_key?
            field.prepare_save(self, new_record: true)
          end

          pk = self.class.connection.insert(self.class.table_name, values, pk_field_to_fetch: pk_field_to_fetch)

          self.pk ||= pk
          self.new_record = false
        end
      end
    end
  end
end
