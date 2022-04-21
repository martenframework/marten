require "./field"

module Marten
  abstract class Schema
    # A field used in the context of a specific schema instance.
    class BoundField
      # Returns the associated field definition.
      getter field

      # Returns the associated schema instance.
      getter schema

      def initialize(@schema : Schema, @field : Field::Base)
      end

      # Returns `true` if the field is errored.
      def errored?
        !schema.errors[field.id].empty?
      end

      # Returns the validation errors associated with the considered field.
      def errors
        schema.errors[field.id]
      end

      # Returns the field value.
      def value
        schema.data[id]? || schema.initial[id]?
      end

      # Returns the field identifier.
      delegate id, to: field

      # Returns `true` if the field is required.
      delegate required?, to: field
    end
  end
end
