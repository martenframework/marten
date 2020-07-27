module Marten
  module DB
    module Field
      abstract class Base
        @primary_key : ::Bool
        @blank : ::Bool
        @null : ::Bool
        @name : ::String?
        @max_size : ::Int32?

        getter id

        def initialize(
          @id : ::String,
          @primary_key = false,
          @blank = false,
          @null = false,
          @name = nil,
          @max_size = nil
        )
        end

        abstract def from_db_result_set(result_set : ::DB::ResultSet)
        abstract def to_db(value) : ::DB::Any

        # Runs custom validation logic for a specific model field and model object.
        #
        # This method should be overriden for each field implementation that requires custom validation logic.
        def validate(record, value)
        end

        protected def perform_validation(record : Model)
          value = record.get_field_value(id)

          if value.nil? && !@null
            record.errors.add(id, null_error_message(record), type: :null)
          elsif empty_value?(value) && !@blank
            record.errors.add(id, blank_error_message(record), type: :blank)
          end

          validate(record, value)
        end

        private def empty_value?(value) : ::Bool
          value.nil?
        end

        private def null_error_message(_record)
          # TODO: add I18n support.
          "This field cannot be null."
        end

        private def blank_error_message(_record)
          # TODO: add I18n support.
          "This field cannot be blank."
        end

        private def raise_unexpected_field_value(value)
          raise Errors::UnexpectedFieldValue.new("Unexpected value received for field '#{id}': #{value}")
        end
      end
    end
  end
end
