module Marten
  module Apps
    class Registry
      def initialize
        @app_configs = {} of String => Config
      end

      def populate(installed_apps : Array(Config.class))
        installed_apps.each do |app|
          raise Errors::InvalidAppConfig.new("App name cannot be empty for app '#{app}'") if app.name.empty?

          if @app_configs.has_key?(app.name)
            raise Errors::InvalidAppConfig.new("App names must be unique, duplicate found: '#{app.name}'")
          end

          @app_configs[app.name] = app.new
        end
      end
    end
  end
end
