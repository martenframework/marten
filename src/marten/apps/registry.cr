module Marten
  module Apps
    class Registry
      def initialize
        @app_configs = {} of String => Config
      end

      def app_configs
        @app_configs.values
      end

      def populate(installed_apps : Array(Config.class))
        installed_apps.each do |app|
          if @app_configs.has_key?(app.label)
            raise Errors::InvalidAppConfig.new("App labels must be unique, duplicate found: '#{app.label}'")
          end

          @app_configs[app.label] = app.new
        end
      end

      # Returns the application config object contaning the passed class.
      def get_containing(klass)
        candidates = [] of Config

        @app_configs.values.each do |config|
          if klass.dir_location.starts_with?(config.class.dir_location)
            remaining = klass.dir_location[config.class.dir_location.size..]
            next unless remaining == "" || remaining[0] == '/'
            candidates << config
          end
        end

        result = candidates.sort_by { |config| config.class.dir_location.size }.reverse.first unless candidates.empty?
        raise "Class '#{klass}' is not part of an application defined in Marten.settings.installed_apps" if result.nil?
        result.not_nil!
      end
    end
  end
end
