module Marten
  module DB
    abstract class Model
      module AppConfig
        macro included
          extend Marten::DB::Model::AppConfig::ClassMethods

          @@app_config : Marten::Apps::Config?

          macro inherited
            def self.dir_location
              __DIR__
            end
          end
        end

        module ClassMethods
          protected def app_config
            @@app_config ||= begin
              config = Marten.apps.get_containing_model(self)

              if config.nil?
                raise "Model class is not part of an application defined in Marten.settings.installed_apps"
              end

              config.not_nil!
            end
          end
        end
      end
    end
  end
end
