module Marten
  module DB
    abstract class Model
      module AppConfig
        macro included
          include Apps::Association
          extend Marten::DB::Model::AppConfig::ClassMethods

          @@app_config : Marten::Apps::Config?

          macro inherited
            # Register the model class to make it available to the associated app config later on.
            Marten.apps.register_model(self)
          end
        end

        module ClassMethods
          protected def app_config
            @@app_config ||= Marten.apps.get_containing(self)
          end
        end
      end
    end
  end
end
