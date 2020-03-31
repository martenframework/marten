module Marten
  module Conf
    # Defines the global settings of a Marten web application.
    class GlobalSettings
      class UnknownSettingsNamespace < Exception; end

      @request_max_parameters : Nil | Int32
      @view404 : Views::Base.class
      @view500 : Views::Base.class

      getter allowed_hosts
      getter databases
      getter debug
      getter host
      getter logger
      getter port
      getter port_reuse
      getter request_max_parameters
      getter secret_key
      getter use_x_forwarded_host
      getter view404
      getter view500

      setter allowed_hosts
      setter debug
      setter host
      setter port
      setter port_reuse
      setter request_max_parameters
      setter secret_key
      setter use_x_forwarded_host
      setter view404
      setter view500

      def initialize
        @allowed_hosts = [] of String
        @debug = false
        @host = "localhost"
        @installed_apps = Array(Marten::App.class).new
        @logger = Logger.new(STDOUT)
        @port = 8000
        @port_reuse = true
        @request_max_parameters = 1000
        @secret_key = ""
        @use_x_forwarded_host = false
        @view404 = Views::Defaults::PageNotFound
        @view500 = Views::Defaults::ServerError
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
