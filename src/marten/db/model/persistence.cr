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
          #   post.complex_attribute = compute_comple_attribute
          # end
          # ```
          def create(**kwargs, &block)
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
          #   post.complex_attribute = compute_comple_attribute
          # end
          def create!(**kwargs, &block)
            object = new(**kwargs)
            yield object
            object.save!
            object
          end
        end

        # :nodoc:
        @destroyed : Bool = false

        # :nodoc:
        @new_record : Bool = true

        # Saves the model instance.
        #
        # If the model instance is new, a new record is created in the DB ; otherwise the existing record is updated.
        # This method will return `true` if the model instance is valid and was created / updated successfully.
        # Otherwise it will return `false` if the model instance validation failed.
        def save(using : Nil | String | Symbol = nil) : Bool
          if valid? && !persisted?
            connection = using.nil? ? self.class.connection : DB::Connection.get(using.to_s)
            connection.transaction do
              insert_or_update(connection)
              true
            end
          else
            false
          end
        end

        # Saves the model instance.
        #
        # If the model instance is new, a new record is created in the DB ; otherwise the existing record is updated.
        # This method will return `true` if the model instance is valid and was created / updated successfully.
        # Otherwise it will raise a `Marten::DB::Errors::InvalidRecord` exception if the model instance validation
        # failed.
        def save!(using : Nil | String | Symbol = nil) : Bool
          save(using: using) || (raise Errors::InvalidRecord.new("Record is invalid"))
        end

        # Reloads the model instance.
        #
        # This methods retrieves the record at the database level and updates the current model instances with the new
        # values.
        def reload
          reloaded = self.class.get!(pk: pk)
          self.assign_field_values(reloaded.field_values)
          @new_record = false
          self
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

        private def insert_or_update(connection)
          if persisted?
            raise NotImplementedError.new("Model records update not implemented yet")
          else
            insert(connection)
          end
        end

        private def insert(connection)
          self.class.fields.each do |field|
            next if field.primary_key?
            field.prepare_save(self, new_record: true)
          end

          values = field_db_values

          if self.class.pk_field.is_a?(Field::AutoTypes)
            pk_field_to_fetch = self.class.pk_field.id
            values.delete(pk_field_to_fetch)
          else
            pk_field_to_fetch = nil
          end

          pk = connection.insert(self.class.table_name, values, pk_field_to_fetch: pk_field_to_fetch)

          self.pk ||= pk
          self.new_record = false
        end
      end
    end
  end
end
