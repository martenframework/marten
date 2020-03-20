module Marten
  module Conf
    class Settings
      getter databases
      getter debug
      getter logger
      getter secret_key

      setter debug
      setter secret_key

      def initialize
        @debug = false
        @installed_apps = Array(Marten::App.class).new
        @secret_key = ""
        @logger = Logger.new(STDOUT)
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
