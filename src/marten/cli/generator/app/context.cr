module Marten
  module CLI
    abstract class Generator
      class App < Generator
        class Context
          getter label
          getter main_app_config

          def initialize(@main_app_config : Apps::Config, @label : String)
          end

          def app_class_name : String
            "#{module_name}::App"
          end

          def located_in_apps_folder? : Bool
            Dir.exists?(Path.new(main_app_config.class._marten_app_location).expand.join("apps"))
          end

          def module_name : String
            label.split("_").map(&.capitalize).join
          end
        end
      end
    end
  end
end
