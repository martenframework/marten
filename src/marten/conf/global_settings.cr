module Marten
  module Conf
    class GlobalSettings
      class UnknownSettingsNamespace < Exception; end

      getter databases
      getter debug
      getter host
      getter logger
      getter port
      getter port_reuse
      getter secret_key

      setter debug
      setter host
      setter port
      setter port_reuse
      setter secret_key

      def initialize
        @debug = false
        @host = "localhost"
        @installed_apps = Array(Marten::App.class).new
        @logger = Logger.new(STDOUT)
        @port = 8000
        @port_reuse = true
        @secret_key = ""
      end

      def database(id = :default)
        db_config = Database.new
        with db_config yield db_config
      end

      def installed_apps=(v)
        @installed_apps = Array(Marten::App.class).new
        @installed_apps.concat(v)
      end

      def logger=(logger : ::Logger)
        @logger = logger
      end

      def setup
        setup_logger_formatting
      end

      macro method_missing(call)
        def {{ call.name }} : Settings
          settings = Marten::Conf.settings_namespaces.fetch("{{ call.name }}", nil)
          return settings unless settings.nil?
          raise UnknownSettingsNamespace.new("No '{{ call.name }}' settings namespace available")
        end
      end

      private def setup_logger_formatting
        logger.progname = "Server"
        logger.formatter = Logger::Formatter.new do |severity, datetime, progname, message, io|
          io << "[#{severity.to_s[0]}] "
          io << "[#{datetime.to_utc}] "
          io << "[#{progname}] "
          io << message
        end
      end
    end
  end
end
