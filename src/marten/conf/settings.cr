module Marten
  module Conf
    abstract class Settings
      abstract def initialize

      def self.namespace(namespace : String | Symbol)
        Marten::Conf.register_settings_namespace(namespace.to_s, self)
      end
    end
  end
end
