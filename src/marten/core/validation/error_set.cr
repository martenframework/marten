module Marten
  module Core
    module Validation
      # Represents a set of validation errors.
      class ErrorSet
        include Indexable(Error)

        DEFAULT_ERROR_TYPE = :invalid

        def initialize
          @errors = [] of Error
        end

        # Returns all the errors associated with a specific field.
        def [](field : Nil | String | Symbol)
          @errors.select { |e| e.field == field.try(&.to_s) }
        end

        # Adds a new global error to the error set.
        #
        # This method can be used to add a new global error (that is not associated with a specific field) to an
        # existing error set. At least a `message` must be specified:
        #
        # ```
        # record.errors.add("This record is invalid!")
        # ```
        #
        # Optionnaly, an error `type` can be explicitely specified, otherwise it defaults to `:invalid`:
        #
        # ```
        # record.errors.add("This record is invalid!", type: :invalid_record)
        # ```
        def add(message : String, *, type : Nil | String | Symbol = nil)
          @errors << Error.new(type: type || DEFAULT_ERROR_TYPE, field: nil, message: message)
        end

        # Adds a new field error to the error set.
        #
        # This method can be used to add a new error associated with a specific field to an existing error set. At least
        # a `field` and a `message` must be specified:
        #
        # ```
        # record.errors.add(:attribute, "This record attribute is invalid")
        # ```
        #
        # Optionnaly, an error `type` can be explicitely specified, otherwise it defaults to `:invalid`:
        #
        # ```
        # records.errors.add(:attribute, "This record attribute is invalid!", type: :invalid_attribute)
        # ```
        def add(field : String | Symbol, message : String, *, type : Nil | String | Symbol = nil)
          @errors << Error.new(type: type || DEFAULT_ERROR_TYPE, field: field, message: message)
        end

        # Returns the global errors (errors that are not associated with a specific field).
        def global
          self[nil]
        end

        # Iterates over all the `Marten::Core::Validation::Error` objects in this error set.
        delegate each, to: @errors

        # Clears all the `Marten::Core::Validation::Error` objects from this error set.
        delegate clear, to: @errors

        # Returns the number of errors.
        delegate size, to: @errors

        # :nodoc:
        delegate unsafe_fetch, to: @errors
      end
    end
  end
end
