module Marten
  module DB
    abstract class Model
      @@app_config : Marten::Apps::Config?

      def self.table_name
        @@table_name ||= %{#{app_config.name.downcase}_#{name.gsub("::", "_").underscore}s}
      end

      private def self.app_config
        @@app_config ||= begin
          config = Marten.apps.get_containing_model(self)

          if config.nil?
            raise Exception.new("Model class is not part of an application defined in Marten.config.installed_apps")
          end

          config.not_nil!
        end
      end

      macro inherited
        def self.dir_location
          __DIR__
        end
      end
    end
  end
end
