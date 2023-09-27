module Marten
  module CLI
    abstract class Generator
      class Model < Generator
        class Context
          @pk_field_definition : FieldDefinition

          getter app_config
          getter field_definitions
          getter name
          getter parent
          getter pk_field_definition

          getter? no_timestamps

          def initialize(
            @app_config : Apps::Config,
            @name : String,
            @field_definitions : Array(FieldDefinition),
            @no_timestamps : Bool = false,
            @parent : String? = nil
          )
            @pk_field_definition = field_definitions.find(&.primary_key?) || default_pk_field_definition
            field_definitions.delete(pk_field_definition)
          end

          def class_name
            app_config.main? ? name : (app_config.class.name.split("::")[...-1] + [name]).join("::")
          end

          def model_filename
            "#{name.underscore}.cr"
          end

          private def default_pk_field_definition
            FieldDefinition.new(
              name: "id",
              type: "big_int",
              qualifier: nil,
              modifiers: [FieldDefinition::Modifier::PRIMARY, FieldDefinition::Modifier::AUTO]
            )
          end
        end
      end
    end
  end
end
