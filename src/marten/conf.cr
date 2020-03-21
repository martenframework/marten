module Marten
  module Conf
    @@settings_namespaces : Hash(String, Settings)?

    def self.register_settings_namespace(namespace : String, settings : Settings.class)
      settings_namespaces[namespace] = settings.new
    end

    def self.settings_namespaces
      @@settings_namespaces ||= {} of String => Settings
    end
  end
end
