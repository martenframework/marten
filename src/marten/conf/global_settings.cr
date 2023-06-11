module Marten
  module Conf
    # Defines the global settings of a Marten web application.
    class GlobalSettings
      @@registered_settings_namespaces = [] of String

      @cache_store : Cache::Store::Base
      @log_backend : ::Log::Backend
      @request_max_parameters : Nil | Int32
      @root_path : String?
      @target_env : String?
      @handler400 : Handlers::Base.class
      @handler403 : Handlers::Base.class
      @handler404 : Handlers::Base.class
      @handler500 : Handlers::Base.class

      # Returns the explicit list of allowed hosts for the application.
      getter allowed_hosts

      # Returns the global cache store.
      getter cache_store

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

      # The default log level used by the application.
      getter log_level

      # Returns the list of middlewares used by the application.
      getter middleware

      # Returns the port the HTTP server running the application will be listening on.
      getter port

      # Returns a boolean indicating whether multiple processes can bind to the same HTTP server port.
      getter port_reuse

      # Returns the maximum number of allowed parameters per request (such as GET or POST parameters).
      getter request_max_parameters

      # Returns the root path of the application.
      getter root_path

      # Returns the secret key of the application.
      getter secret_key

      # Returns the default time zone used by the application when it comes to display date times.
      getter time_zone

      # Returns a boolean indicating whether the X-Forwarded-Host header is used to look for the host.
      getter use_x_forwarded_host

      # Returns a boolean indicating if the X-Forwarded-Port header is used to determine the port of a request.
      getter use_x_forwarded_port

      # Returns a boolean indicating if the X-Forwarded-Proto header is used to determine whether a request is secure.
      getter use_x_forwarded_proto

      # Returns the configured handler class that should generate responses for Bad Request responses (HTTP 400).
      getter handler400

      # Returns the configured handler class that should generate responses for Permission Denied responses (HTTP 403).
      getter handler403

      # Returns the configured handler class that should generate responses for Not Found responses (HTTP 404).
      getter handler404

      # Returns the configured handler class that should generate responses for Internal Error responses (HTTP 500).
      getter handler500

      # Returns the value to use for the X-Frame-Options header when the associated middleware is used.
      #
      # The value of this setting will be used by the `Marten::Middleware::XFrameOptions` middleware when inserting the
      # X-Frame-Options header in HTTP responses.
      getter x_frame_options

      # Allows to set the explicit list of allowed hosts for the application.
      #
      # The application has to be explictely configured to serve a list of allowed hosts. This is to mitigate HTTP Host
      # header attacks.
      setter allowed_hosts

      # Allows to set the global cache store.
      setter cache_store

      # Allows to activate or deactive debug mode.
      setter debug

      # Allows to set the host the HTTP server running the application will be listening on.
      setter host

      # Allows to set the default log level that will be used by the application (defaults to info).
      setter log_level

      # Allows to set the port the HTTP server running the application will be listening on.
      setter port

      # Allows to indicate whether multiple processes can bind to the same HTTP server port.
      setter port_reuse

      # Allows to set the maximum number of allowed parameters per request (such as GET or POST parameters).
      #
      # This maximum limit is used to prevent large requests that could be used in the context of DOS attacks. Setting
      # this value to `nil` will disable this behaviour.
      setter request_max_parameters

      # Allows to set the secret key of the application.
      #
      # The secret key will be used provide cryptographic signing. It should be unique and unpredictable.
      setter secret_key

      # Allows to set the default time zone used by the application when it comes to display date times.
      setter time_zone

      # Allows to set whether the X-Forwarded-Host header is used to look for the host.
      setter use_x_forwarded_host

      # Allows to set whether the X-Forwarded-Port header is used to determine the port of a request.
      setter use_x_forwarded_port

      # Allows to set whether the X-Forwarded-Proto header should be used to determine whether a request is secure.
      setter use_x_forwarded_proto

      # Allows to set the handler class that should generate responses for Bad Request responses (HTTP 400).
      setter handler400

      # Allows to set the handler class that should generate responses for Permission Denied responses (HTTP 403).
      setter handler403

      # Allows to set the handler class that should generate responses for Not Found responses (HTTP 404).
      setter handler404

      # Allows to set the handler class that should generate responses for Internal Error responses (HTTP 500).
      setter handler500

      # :nodoc:
      def self.register_settings_namespace(ns : String)
        if settings_namespace_registered?(ns)
          raise Errors::InvalidConfiguration.new("Setting namespace '#{ns}' is defined more than once")
        end

        @@registered_settings_namespaces << ns
      end

      # :nodoc:
      def self.settings_namespace_registered?(ns : String) : Bool
        @@registered_settings_namespaces.includes?(ns)
      end

      def initialize
        @allowed_hosts = [] of String
        @cache_store = Cache::Store::Memory.new
        # @cache_store = Cache::MemoryStore(String, String).new(expires_in: 15.minutes)
        @databases = [] of Database
        @debug = false
        @host = "127.0.0.1"
        @installed_apps = Array(Marten::Apps::Config.class).new
        log_formatter = ::Log::Formatter.new do |entry, io|
          io << "[#{entry.severity.to_s[0]}] "
          io << "[#{entry.timestamp.to_utc}] "
          io << "[Server] "
          io << entry.message

          entry.data.each do |k, v|
            io << "\n  #{k}: #{v}"
          end
        end
        @log_backend = ::Log::IOBackend.new(formatter: log_formatter)
        @log_level = ::Log::Severity::Info
        @middleware = Array(Marten::Middleware.class).new
        @port = 8000
        @port_reuse = true
        @request_max_parameters = 1000
        @secret_key = ""
        @time_zone = Time::Location.load("UTC")
        @use_x_forwarded_host = false
        @use_x_forwarded_port = false
        @use_x_forwarded_proto = false
        @handler400 = Handlers::Defaults::BadRequest
        @handler403 = Handlers::Defaults::PermissionDenied
        @handler404 = Handlers::Defaults::PageNotFound
        @handler500 = Handlers::Defaults::ServerError
        @x_frame_options = "DENY"
      end

      # Provides access to assets settings.
      def assets
        @assets ||= GlobalSettings::Assets.new
      end

      # Provides access to the content security policy settings.
      #
      # These setting values will be used by the `Marten::Middleware::ContentSecurityPolicy` middleware when inserting
      # the Content-Security-Policy header in HTTP responses.
      def content_security_policy
        @content_security_policy ||= GlobalSettings::ContentSecurityPolicy.new
      end

      # :ditto:
      def content_security_policy(&)
        yield content_security_policy
      end

      # Provides access to request forgery protection settings.
      def csrf
        @csrf ||= GlobalSettings::CSRF.new
      end

      # Allows to configure a specific database connection for the application.
      def database(id = DB::Connection::DEFAULT_CONNECTION_NAME, &)
        db_config = @databases.find { |d| d.id.to_s == id.to_s }
        not_yet_defined = db_config.nil?
        db_config = Database.new(id.to_s) if db_config.nil?
        db_config.not_nil!.with_target_env(@target_env) do |db_config_with_target_env|
          yield db_config_with_target_env
        end
        @databases << db_config if not_yet_defined
      end

      # Provides access to emailing settings.
      def emailing
        @emailing ||= GlobalSettings::Emailing.new
      end

      # Provides access to internationalization settings.
      def i18n
        @i18n ||= GlobalSettings::I18n.new
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

      # Provides access to media files settings.
      def media_files
        @media_files ||= GlobalSettings::MediaFiles.new
      end

      # Allows to define the list of middlewares used by the application.
      def middleware=(v)
        @middleware = Array(Marten::Middleware.class).new
        @middleware.concat(v)
      end

      # Allows to set the root path of the application.
      #
      # The root path of the application specifies the actual location of the project sources in your system. This can
      # prove helpful in scenarios where the project was compiled in a specific location different from the final
      # destination where the project sources are copied. For instance, platforms like Heroku often fall under this
      # category. By configuring the root path, you can ensure that your application correctly locates the required
      # project sources and avoids any discrepancies arising from inconsistent source paths. This can prevent issues
      # related to missing dependencies or missing app-related files (eg. locales or templates) and make your
      # application more robust and reliable.
      def root_path=(path : Nil | Path | String | Symbol)
        @root_path = path.try(&.to_s)
      end

      # Provides access to sessions settings.
      def sessions
        @sessions ||= GlobalSettings::Sessions.new
      end

      # Provides access to SSL redirect settings.
      def ssl_redirect
        @ssl_redirect ||= GlobalSettings::SSLRedirect.new
      end

      # Provides access to strict transport security settings.
      def strict_transport_security
        @strict_transport_security ||= GlobalSettings::StrictTransportSecurity.new
      end

      # Provides access to templates settings.
      def templates
        @templates ||= GlobalSettings::Templates.new
      end

      # :nodoc:
      def with_target_env(target_env : String?, &)
        current_target_env = @target_env
        @target_env = target_env
        yield self
      ensure
        @target_env = current_target_env
      end

      # Allows to set the value to use for the X-Frame-Options header when the associated middleware is used.
      #
      # This value will be used by the `Marten::Middleware::XFrameOptions` middleware when inserting the
      # X-Frame-Options header in HTTP responses.
      def x_frame_options=(x_frame_options : String | Symbol)
        @x_frame_options = x_frame_options.to_s
      end

      protected def setup
        setup_log_backend
        setup_db_connections
      end

      private def setup_log_backend
        ::Log.setup(log_level, log_backend)
      end

      private def setup_db_connections
        databases.each do |db_config|
          db_config.validate
          DB::Connection.register(db_config)
        end

        sessions.validate
      end
    end
  end
end
