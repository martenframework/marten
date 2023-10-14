module Marten
  module CLI
    abstract class Generator
      class Schema < Generator
        class Context
          getter app_config
          getter field_definitions
          getter name
          getter parent

          def initialize(
            @app_config : Apps::Config,
            @name : String,
            @field_definitions : Array(FieldDefinition),
            @parent : String? = nil
          )
          end

          def class_name
            app_config.main? ? name : (app_config.class.name.split("::")[...-1] + [name]).join("::")
          end

          def schema_filename
            "#{name.underscore}.cr"
          end
        end
      end
    end
  end
end
