module Marten
  module DB
    abstract class Model
      module Persistence
        # :nodoc:
        @destroyed : Bool = false

        # :nodoc:
        @new_record : Bool = true

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
      end
    end
  end
end
