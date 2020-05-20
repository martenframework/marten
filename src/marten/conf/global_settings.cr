module Marten
  module Conf
    # Defines the global settings of a Marten web application.
    class GlobalSettings
      class UnknownSettingsNamespace < Exception; end

      @request_max_parameters : Nil | Int32
      @view400 : Views::Base.class
      @view403 : Views::Base.class
      @view404 : Views::Base.class
      @view500 : Views::Base.class

      # Returns the explicit list of allowed hosts for the application.
      getter allowed_hosts

      # Returns the application database configurations.
      getter databases

      # Returns a boolean indicating whether the application runs in debug mode.
      getter debug

      # Returns the host the HTTP server running the application will be listening on.
      getter host

      # Returns the third-party applications used by the project.
      getter installed_apps

      # Returns the log backend used by the application.
      getter log_backend

      # Returns the port the HTTP server running the application will be listening on.
      getter port

      # Returns a boolean indicating whether multiple processes can bind to the same HTTP server port.
      getter port_reuse

      # Returns the maximum number of allowed parameters per request (such as GET or POST parameters).
      getter request_max_parameters

      # Returns the secret key of the application.
      getter secret_key

      # Returns a boolean indicating whether the X-Forwarded-Host header is used to look for the host.
      getter use_x_forwarded_host

      # Returns the configured view class that should generate responses for Bad Request responses (HTTP 400).
      getter view400

      # Returns the configured view class that should generate responses for Permission Denied responses (HTTP 403).
      getter view403

      # Returns the configured view class that should generate responses for Not Found responses (HTTP 404).
      getter view404

      # Returns the configured view class that should generate responses for Internal Error responses (HTTP 500).
      getter view500

      # Allows to set the explicit list of allowed hosts for the application.
      #
      # The application has to be explictely configured to serve a list of allowed hosts. This is to mitigate HTTP Host
      # header attacks.
      setter allowed_hosts

      # Allows to activate or deactive debug mode.
      setter debug

      # Allows to set the host the HTTP server running the application will be listening on.
      setter host

      # Allows to set the port the HTTP server running the application will be listening on.
      setter port

      # Allows to indicate whether multiple processes can bind to the same HTTP server port.
      setter port_reuse

      # Allows to set the maximum number of allowed parameters per request (such as GET or POST parameters).
      #
      # This maximum limit is used to prevent large requests that could be used in the context of DOS attacks. Setting
      # this value to `nil` will disable this behaviour.
      setter request_max_parameters

      # Allows to set to the secret key of the application.
      #
      # The secret key will be used provide cryptographic signing. It should be unique and unpredictable.
      setter secret_key

      # Allows to set whether the X-Forwarded-Host header is used to look for the host.
      setter use_x_forwarded_host

      # Allows to set the view class that should generate responses for Bad Request responses (HTTP 400).
      setter view400

      # Allows to set the view class that should generate responses for Permission Denied responses (HTTP 403).
      setter view403

      # Allows to set the view class that should generate responses for Not Found responses (HTTP 404).
      setter view404

      # Allows to set the view class that should generate responses for Internal Error responses (HTTP 500).
      setter view500

      def initialize
        @allowed_hosts = [] of String
        @databases = [] of Database
        @debug = false
        @host = "localhost"
        @installed_apps = Array(Marten::Apps::Config.class).new
        @log_backend = ::Log::IOBackend.new
        @port = 8000
        @port_reuse = true
        @request_max_parameters = 1000
        @secret_key = ""
        @use_x_forwarded_host = false
        @view400 = Views::Defaults::BadRequest
        @view403 = Views::Defaults::PermissionDenied
        @view404 = Views::Defaults::PageNotFound
        @view500 = Views::Defaults::ServerError
      end

      # Allows to configure a specific database connection for the application.
      def database(id = :default)
        db_config = @databases.find { |d| d.id.to_s == id.to_s }
        not_yet_defined = db_config.nil?
        db_config = Database.new(id.to_s) if db_config.nil?
        yield db_config.not_nil!
        @databases << db_config if not_yet_defined
      end

      # Allows to define the third-party applications used by the project.
      def installed_apps=(v)
        @installed_apps = Array(Marten::Apps::Config.class).new
        @installed_apps.concat(v)
      end

      # Allows to set the log backend used by the application.
      def log_backend=(log_backend : ::Log::Backend)
        @log_backend = log_backend
      end

      protected def setup
        setup_log_backend
        setup_db_connections
      end

      macro method_missing(call)
        def {{ call.name }} : Settings
          settings = Marten::Conf.settings_namespaces.fetch("{{ call.name }}", nil)
          return settings unless settings.nil?
          raise UnknownSettingsNamespace.new("No '{{ call.name }}' settings namespace available")
        end
      end

      private def setup_log_backend
        # TODO: define log backend as part of log backend initialization instead.
        log_backend.as(::Log::IOBackend).formatter = ::Log::Formatter.new do |entry, io|
          io << "[#{entry.severity.to_s[0]}] "
          io << "[#{entry.timestamp.to_utc}] "
          io << "[Server] "
          io << entry.message
        end
        ::Log.builder.bind("marten.*", :debug, log_backend)
      end

      private def setup_db_connections
        databases.each do |db_config|
          db_config.validate
          DB::Connection.register(db_config)
        end
      end
    end
  end
end
