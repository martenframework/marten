module Marten
  module DB
    module Field
      # Abstract base field implementation.
      abstract class Base
        @primary_key : ::Bool
        @blank : ::Bool
        @null : ::Bool
        @db_column : ::String | Symbol | Nil

        # Returns the ID of the field used in the associated model.
        getter id

        def initialize(
          @id : ::String,
          @primary_key = false,
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil
        )
        end

        # Returns the default value of the field if any.
        abstract def default

        # Converts the raw DB value to the corresponding field value.
        abstract def from_db(value)

        # Extracts the field value from a DB result set and returns the right object corresponding to this value.
        abstract def from_db_result_set(result_set : ::DB::ResultSet)

        # Returns a migration column object corresponding to the field at hand.
        abstract def to_column : Management::Column::Base?

        # Converts the field value to the corresponding DB value.
        abstract def to_db(value) : ::DB::Any

        # Returns a boolean indicating whether the field can be blank validation-wise.
        def blank?
          @blank
        end

        # Returns the name of the column associated with the considered field.
        def db_column
          @db_column.try(&.to_s) || @id
        end

        # Returns a mandatory non-`nil` version of the DB column (and raise otherwise).
        def db_column! : ::String
          db_column.not_nil!
        end

        # Returns `true` if the field is associated with an in-DB column.
        def db_column?
          !db_column.nil?
        end

        # Returns `true` if the value is considered empty by the field.
        def empty_value?(value) : ::Bool
          value.nil?
        end

        # Returns `true` if true should be returned for `getter?`-like methods for the field.
        #
        # Usually, `true` would be returned for values that are truthy and not empty, but this logic can be overridden
        # on a per-field implementation basis.
        def getter_value?(value) : ::Bool
          return false if !truthy_value?(value)

          !empty_value?(value)
        end

        # Returns true if an index should be created at the database level for the field.
        def index?
          @index
        end

        # Returns a boolean indicating whether the field can be null at the database level.
        def null?
          @null
        end

        # :nodoc:
        def perform_validation(record : Model)
          value = record.get_field_value(id)

          if value.nil? && !@null
            record.errors.add(id, null_error_message(record), type: :null)
          elsif empty_value?(value) && !@blank
            record.errors.add(id, blank_error_message(record), type: :blank)
          end

          validate(record, value)
        end

        # Runs pre-save logic for the specific field and record at hand.
        #
        # This method does nothing by default but can be overridden for specific fields that need to set values on the
        # model instance before save or perform any pre-save logic.
        def prepare_save(record, new_record = false)
        end

        # Returns a boolean indicating whether the field is a primary key.
        def primary_key?
          @primary_key
        end

        # Returns the related model associated with the field.
        #
        # This method will raise a `NotImplementedError` exception by default and should only be overriden if the
        # `#relation?` method returns `true` (this is the case for fields such as many to one, one to one, etc).
        def related_model
          raise NotImplementedError.new("#relation_model must be implemented by subclasses if necessary")
        end

        # Returns true if the field is a relation.
        #
        # By default this method will always return `false`. It should be overriden if the field is intended to handle
        # a relation with another model (eg. like many to one or one to one fields).
        def relation?
          false
        end

        # Returns the name of the relation on the model associated with the field.
        #
        # This method will raise a `NotImplementedError` exception by default and should only be overriden if the
        # `#relation?` method returns `true` (this is the case for fields such as many to one, one to one, etc).
        def relation_name
          raise NotImplementedError.new("#relation_name must be implemented by subclasses if necessary")
        end

        # Returns `true` if the if the value is considered truthy by the field.
        def truthy_value?(value)
          !(value == false || value == 0 || value.nil?)
        end

        # Returns a boolean indicating whether the field value should be unique throughout the associated table.
        def unique?
          @unique
        end

        # Runs custom validation logic for a specific model field and model object.
        #
        # This method should be overriden for each field implementation that requires custom validation logic.
        def validate(record, value)
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
        end

        # :nodoc:
        macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
          # Registers the field to the model class.

          class ::{{ model_klass }}
            register_field(
              {{ @type }}.new(
                {{ field_id.stringify }},
                {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %}
              )
            )

            {% if !model_klass.resolve.abstract? %}
              @[Marten::DB::Model::Table::FieldInstanceVariable(
                field_klass: {{ @type }},
                field_kwargs: {% unless kwargs.is_a?(NilLiteral) %}{{ kwargs }}{% else %}nil{% end %},
                field_type: {{ field_ann[:exposed_type] }}{% if field_ann[:additional_type] %} | {{ field_ann[:additional_type] }}{% end %} # ameba:disable Layout/LineLength
              )]

              @{{ field_id }} : {{ field_ann[:exposed_type] }}?

              def {{ field_id }} : {{ field_ann[:exposed_type] }}?
                @{{ field_id }}
              end

              def {{ field_id }}!
                @{{ field_id }}.not_nil!
              end

              def {{ field_id }}?
                self.class.get_field({{ field_id.stringify }}).getter_value?({{ field_id }})
              end

              def {{ field_id }}=(@{{ field_id }} : {{ field_ann[:exposed_type] }}?); end
            {% end %}
          end
        end

        private def blank_error_message(_record)
          I18n.t("marten.db.field.base.errors.blank")
        end

        private def null_error_message(_record)
          I18n.t("marten.db.field.base.errors.nil")
        end

        private def raise_unexpected_field_value(value)
          raise Errors::UnexpectedFieldValue.new("Unexpected value received for field '#{id}': #{value}")
        end
      end
    end
  end
end
