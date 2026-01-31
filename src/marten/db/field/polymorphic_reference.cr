module Marten
  module DB
    module Field
      # :nodoc:
      #
      # Represents a polymorphic reference field.
      #
      # This field type is used internally by the `polymorphic` field type to store the reference of the primary key of
      # the related record. It should not be used directly in model definitions.
      class PolymorphicReference < Base
        def initialize(
          @id : ::String,
          @types : Array(Model.class),
          @blank = false,
          @null = false,
          @index = false,
        )
          @primary_key = false
          @unique = false
        end

        def default
          # No-op
        end

        def from_db(value) : Marten::DB::Field::ReferenceDBTypes
          case value
          when Marten::DB::Field::ReferenceDBTypes
            value
          when ::UUID
            value.hexstring
          else
            raise_unexpected_field_value(value)
          end
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Marten::DB::Field::ReferenceDBTypes
          from_db(result_set.read(Marten::DB::Field::ReferenceDBTypes | ::UUID))
        end

        def to_column : Management::Column::Base?
          unique_types = @types.map(&.pk_field.class).uniq!
          if unique_types.size > 1
            raise Errors::InvalidField.new(
              "All the types of a polymorphic field must have the same type of model primary " \
              "key field. Field '#{id}'' has types #{unique_types.map(&.name).join(", ")}."
            )
          end

          column = @types.first.pk_field.to_column.clone.not_nil!
          column.name = db_column!
          column.primary_key = false
          column.unique = false
          column.null = null?
          column.index = index?
          column.default = nil

          if column.is_a?(Management::Column::BigInt) || column.is_a?(Management::Column::Int)
            column.auto = false
          end

          column
        end

        def to_db(value) : ::DB::Any
          @types.first.pk_field.to_db(value).as(ReferenceDBTypes)
        end
      end
    end
  end
end
