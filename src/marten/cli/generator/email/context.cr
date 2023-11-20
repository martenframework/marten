module Marten
  module CLI
    abstract class Generator
      class Email < Generator
        class Context
          getter app_config
          getter name
          getter parent

          def initialize(@app_config : Apps::Config, @name : String, @parent : String? = nil)
          end

          def email_filename
            "#{name.underscore}.cr"
          end

          def class_name
            app_config.main? ? name : (app_config.class.name.split("::")[...-1] + [name]).join("::")
          end

          def html_template_filepath
            "#{templates_path}#{name.underscore}.html"
          end

          def text_template_filepath
            "#{templates_path}#{name.underscore}.txt"
          end

          private def templates_path
            app_config.main? ? "emails/" : "#{app_config.label}/emails/"
          end
        end
      end
    end
  end
end
