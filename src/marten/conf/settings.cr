module Marten
  module Conf
    class Settings
      getter databases
      getter debug
      getter secret_key

      setter debug
      setter secret_key

      def initialize
        @secret_key = ""
        @debug = false
        @installed_apps = Array(Marten::App.class).new
      end

      def installed_apps=(v)
        @installed_apps = Array(Marten::App.class).new
        @installed_apps.concat(v)
      end

      def database(id = :default)
        db_config = Database.new
        yield db_config
      end
    end
  end
end
