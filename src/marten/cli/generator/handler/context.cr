module Marten
  module CLI
    abstract class Generator
      class Handler < Generator
        class Context
          getter app_config
          getter name
          getter parent

          def initialize(@app_config : Apps::Config, @name : String, @parent : String? = nil)
          end

          def handler_filename
            "#{name.underscore}.cr"
          end

          def class_name
            app_config.main? ? name : (app_config.class.name.split("::")[...-1] + [name]).join("::")
          end
        end
      end
    end
  end
end
