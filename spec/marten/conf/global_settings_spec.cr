require "./spec_helper"

describe Marten::Conf::GlobalSettings do
  describe "::register_settings_namespace" do
    it "allows to register a specific settings namespace" do
      Marten::Conf::GlobalSettings.settings_namespace_registered?("testing_global_settings_1").should be_false
      Marten::Conf::GlobalSettings.register_settings_namespace("testing_global_settings_1")
      Marten::Conf::GlobalSettings.settings_namespace_registered?("testing_global_settings_1").should be_true
    end

    it "raises if a settings namespace is registered more than once" do
      Marten::Conf::GlobalSettings.register_settings_namespace("testing_global_settings_2")
      expect_raises(Marten::Conf::Errors::InvalidConfiguration) do
        Marten::Conf::GlobalSettings.register_settings_namespace("testing_global_settings_2")
      end
    end
  end

  describe "::settings_namespace_registered?" do
    it "returns true if the passed namespace string is registered" do
      Marten::Conf::GlobalSettings.register_settings_namespace("testing_global_settings_3")
      Marten::Conf::GlobalSettings.settings_namespace_registered?("testing_global_settings_3").should be_true
    end

    it "returns false if the passed namespace string is not registered" do
      Marten::Conf::GlobalSettings.settings_namespace_registered?("testing_global_settings_unknown").should be_false
    end
  end

  describe "#allowed_hosts" do
    it "returns an empty list by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.allowed_hosts.empty?.should be_true
    end

    it "returns the list of allowed hosts if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.allowed_hosts = ["localhost"]
      global_settings.allowed_hosts.should eq ["localhost"]
    end
  end

  describe "#allowed_hosts=" do
    it "allows to set the list of allowed hosts for the application" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.allowed_hosts = ["localhost"]
      global_settings.allowed_hosts.should eq ["localhost"]
    end
  end

  describe "#assets" do
    it "returns the assets configuration" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.assets.should be_a Marten::Conf::GlobalSettings::Assets
    end
  end

  describe "#cache_store" do
    it "returns a memory store by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.cache_store.should be_a Marten::Cache::Store::Memory
    end

    it "returns the configured store" do
      global_settings = Marten::Conf::GlobalSettings.new
      null_store = Marten::Cache::Store::Null.new

      global_settings.cache_store = null_store
      global_settings.cache_store.should eq null_store
    end
  end

  describe "#cache_store=" do
    it "allows to configure the cache store" do
      global_settings = Marten::Conf::GlobalSettings.new
      null_store = Marten::Cache::Store::Null.new

      global_settings.cache_store = null_store
      global_settings.cache_store.should eq null_store
    end
  end

  describe "#content_security_policy" do
    it "returns the content security configuration" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.content_security_policy.should be_a Marten::Conf::GlobalSettings::ContentSecurityPolicy
    end

    it "yiels the content security policy configuration" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.content_security_policy do |csp|
        csp.should be_a Marten::Conf::GlobalSettings::ContentSecurityPolicy
      end
    end
  end

  describe "#csrf" do
    it "returns the CSRF configuration" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.csrf.should be_a Marten::Conf::GlobalSettings::CSRF
    end
  end

  describe "#databases" do
    it "returns an empty list by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.databases.empty?.should be_true
    end

    it "returns the list of configured databases" do
      global_settings = Marten::Conf::GlobalSettings.new

      global_settings.database do |db|
        db.backend = :sqlite
        db.name = "db.sql"
      end

      global_settings.database :other do |db|
        db.backend = :sqlite
        db.name = "other_db.sql"
      end

      global_settings.databases.size.should eq 2

      global_settings.databases[0].id.should eq Marten::DB::Connection::DEFAULT_CONNECTION_NAME
      global_settings.databases[0].backend.should eq "sqlite"
      global_settings.databases[0].name.should eq "db.sql"

      global_settings.databases[1].id.should eq "other"
      global_settings.databases[1].backend.should eq "sqlite"
      global_settings.databases[1].name.should eq "other_db.sql"
    end
  end

  describe "#database" do
    it "allows to configure the default DB connection" do
      global_settings = Marten::Conf::GlobalSettings.new

      global_settings.database do |db|
        db.backend = :sqlite
        db.name = "db.sql"
      end

      global_settings.databases.size.should eq 1

      global_settings.databases[0].id.should eq Marten::DB::Connection::DEFAULT_CONNECTION_NAME
      global_settings.databases[0].backend.should eq "sqlite"
      global_settings.databases[0].name.should eq "db.sql"
    end

    it "allows to configure a non-default DB connection" do
      global_settings = Marten::Conf::GlobalSettings.new

      global_settings.database :other do |db|
        db.backend = :sqlite
        db.name = "other_db.sql"
      end

      global_settings.databases.size.should eq 1

      global_settings.databases[0].id.should eq "other"
      global_settings.databases[0].backend.should eq "sqlite"
      global_settings.databases[0].name.should eq "other_db.sql"
    end
  end

  describe "#debug" do
    it "returns false by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.debug.should be_false
    end

    it "returns true if debug mode is enabled" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.debug = true
      global_settings.debug.should be_true
    end
  end

  describe "#debug=" do
    it "allows to enable or disable the debug mode" do
      global_settings = Marten::Conf::GlobalSettings.new

      global_settings.debug = true
      global_settings.debug.should be_true

      global_settings.debug = false
      global_settings.debug.should be_false
    end
  end

  describe "#emailing" do
    it "returns the emailing configuration" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.emailing.should be_a Marten::Conf::GlobalSettings::Emailing
    end
  end

  describe "#host" do
    it "returns 127.0.0.1 by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.host.should eq "127.0.0.1"
    end

    it "returns the configured HTTP server host value" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.host = "192.168.1.1"
      global_settings.host.should eq "192.168.1.1"
    end
  end

  describe "#host=" do
    it "allows to configure the HTTP server host" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.host = "192.168.1.1"
      global_settings.host.should eq "192.168.1.1"
    end
  end

  describe "#i18n" do
    it "returns the i18n configuration" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.i18n.should be_a Marten::Conf::GlobalSettings::I18n
    end
  end

  describe "#installed_apps" do
    it "returns an empty array by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.installed_apps.empty?.should be_true
    end

    it "returns the list of installed apps if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.installed_apps = [Marten::Conf::GlobalSettingsSpec::TestAppConfig]
      global_settings.installed_apps.should eq [Marten::Conf::GlobalSettingsSpec::TestAppConfig]
    end
  end

  describe "#installed_apps=" do
    it "allows to configure the list of installed apps" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.installed_apps = [Marten::Conf::GlobalSettingsSpec::TestAppConfig]
      global_settings.installed_apps.should eq [Marten::Conf::GlobalSettingsSpec::TestAppConfig]
    end
  end

  describe "#log_backend" do
    it "returns the IOBackend instance by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.log_backend.should be_a ::Log::IOBackend
    end

    it "returns the configured log backend if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.log_backend = ::Log::MemoryBackend.new
      global_settings.log_backend.should be_a ::Log::MemoryBackend
    end
  end

  describe "#log_backend=" do
    it "allows to set a specific log backend to use" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.log_backend = ::Log::MemoryBackend.new
      global_settings.log_backend.should be_a ::Log::MemoryBackend
    end
  end

  describe "#log_level" do
    it "returns the info log level by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.log_level.should eq Log::Severity::Info
    end

    it "returns the configured log level if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.log_level = Log::Severity::Debug
      global_settings.log_level.should eq Log::Severity::Debug
    end
  end

  describe "#log_level=" do
    it "allows to set a specific log level to use" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.log_level = Log::Severity::Debug
      global_settings.log_level.should eq Log::Severity::Debug
    end
  end

  describe "#media_files" do
    it "returns the media files configuration" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.media_files.should be_a Marten::Conf::GlobalSettings::MediaFiles
    end
  end

  describe "#port" do
    it "returns 8000 by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.port.should eq 8000
    end

    it "returns the configured port if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.port = 80
      global_settings.port.should eq 80
    end
  end

  describe "#port=" do
    it "allows to configure the HTTP server port" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.port = 80
      global_settings.port.should eq 80
    end
  end

  describe "#port_reuse" do
    it "returns true by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.port_reuse.should be_true
    end

    it "returns the specific port reuse configuration if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.port_reuse = false
      global_settings.port_reuse.should be_false
    end
  end

  describe "#port_reuse=" do
    it "allows to configure whether the port_reuse boolean configuration option" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.port_reuse = false
      global_settings.port_reuse.should be_false
    end
  end

  describe "#request_max_parameters" do
    it "returns 1000 by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.request_max_parameters.should eq 1000
    end

    it "returns the specific request max parameters limit if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.request_max_parameters = 500
      global_settings.request_max_parameters.should eq 500
    end
  end

  describe "#request_max_parameters=" do
    it "allows to configure the allowed request max parameters" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.request_max_parameters = 500
      global_settings.request_max_parameters.should eq 500
    end

    it "can be set to nil to disable the protection" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.request_max_parameters = nil
      global_settings.request_max_parameters.should be_nil
    end
  end

  describe "#root_path" do
    it "returns nil by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.root_path.should be_nil
    end

    it "returns the configured root path" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.root_path = "/app"
      global_settings.root_path.should eq "/app"
    end
  end

  describe "#root_path=" do
    it "allows to configure the root path from a string" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.root_path = "/app"
      global_settings.root_path.should eq "/app"
    end

    it "allows to configure the root path from a symbol" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.root_path = :"/app"
      global_settings.root_path.should eq "/app"
    end

    it "allows to configure the root path from a path object" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.root_path = Path["/app"]
      global_settings.root_path.should eq "/app"
    end

    it "allows to reset the configured value by specifying nil" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.root_path = "/app"
      global_settings.root_path = nil
      global_settings.root_path.should be_nil
    end
  end

  describe "#secret_key" do
    it "returns an empty string by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.secret_key.should eq ""
    end

    it "returns the secret key if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.secret_key = "not_secret"
      global_settings.secret_key.should eq "not_secret"
    end
  end

  describe "#secret_key=" do
    it "allows to set the app secret key" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.secret_key = "not_secret"
      global_settings.secret_key.should eq "not_secret"
    end
  end

  describe "#sessions" do
    it "returns the sessions configuration" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.sessions.should be_a Marten::Conf::GlobalSettings::Sessions
    end
  end

  describe "#ssl_redirect" do
    it "returns the SSL redirect configuration" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.ssl_redirect.should be_a Marten::Conf::GlobalSettings::SSLRedirect
    end
  end

  describe "#strict_transport_security" do
    it "returns the strict transport security configuration" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.strict_transport_security.should be_a Marten::Conf::GlobalSettings::StrictTransportSecurity
    end
  end

  describe "#templates" do
    it "returns the templates configuration" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.templates.should be_a Marten::Conf::GlobalSettings::Templates
    end
  end

  describe "#time_zone" do
    it "returns a UTC time zone location by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.time_zone.should eq Time::Location.load("UTC")
    end

    it "returns the configured time zone location if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.time_zone = Time::Location.load("Europe/Paris")
      global_settings.time_zone.should eq Time::Location.load("Europe/Paris")
    end
  end

  describe "#time_zone=" do
    it "allows to configure tje time zone of the application" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.time_zone = Time::Location.load("EST")
      global_settings.time_zone.should eq Time::Location.load("EST")
    end
  end

  describe "#use_x_forwarded_host" do
    it "returns false by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.use_x_forwarded_host.should be_false
    end

    it "returns the configured boolean value if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.use_x_forwarded_host = true
      global_settings.use_x_forwarded_host.should be_true
    end
  end

  describe "#use_x_forwarded_host=" do
    it "allows to configure whether the X-Forwarded-Host header should be used" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.use_x_forwarded_host = true
      global_settings.use_x_forwarded_host.should be_true
    end
  end

  describe "#use_x_forwarded_port" do
    it "returns false by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.use_x_forwarded_port.should be_false
    end

    it "returns the configured boolean value if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.use_x_forwarded_port = true
      global_settings.use_x_forwarded_port.should be_true
    end
  end

  describe "#use_x_forwarded_port=" do
    it "allows to configure whether the X-Forwarded-Port header should be used" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.use_x_forwarded_port = true
      global_settings.use_x_forwarded_port.should be_true
    end
  end

  describe "#use_x_forwarded_proto" do
    it "returns false by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.use_x_forwarded_proto.should be_false
    end

    it "returns the configured boolean value if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.use_x_forwarded_proto = true
      global_settings.use_x_forwarded_proto.should be_true
    end
  end

  describe "#use_x_forwarded_proto=" do
    it "allows to configure whether the X-Forwarded-Proto header should be used" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.use_x_forwarded_proto = true
      global_settings.use_x_forwarded_proto.should be_true
    end
  end

  describe "#handler400" do
    it "#returns Marten::Handlers::Defaults::BadRequest by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.handler400.should eq Marten::Handlers::Defaults::BadRequest
    end

    it "returns the configured handler class if explictely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.handler400 = Marten::Conf::GlobalSettingsSpec::TestHandler
      global_settings.handler400.should eq Marten::Conf::GlobalSettingsSpec::TestHandler
    end
  end

  describe "#handler400=" do
    it "allows to configure the handler class used for bad request responses" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.handler400 = Marten::Conf::GlobalSettingsSpec::TestHandler
      global_settings.handler400.should eq Marten::Conf::GlobalSettingsSpec::TestHandler
    end
  end

  describe "#handler403" do
    it "#returns Marten::Handlers::Defaults::PermissionDenied by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.handler403.should eq Marten::Handlers::Defaults::PermissionDenied
    end

    it "returns the configured handler class if explictely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.handler403 = Marten::Conf::GlobalSettingsSpec::TestHandler
      global_settings.handler403.should eq Marten::Conf::GlobalSettingsSpec::TestHandler
    end
  end

  describe "#handler403=" do
    it "allows to configure the handler class used for permission denied responses" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.handler403 = Marten::Conf::GlobalSettingsSpec::TestHandler
      global_settings.handler403.should eq Marten::Conf::GlobalSettingsSpec::TestHandler
    end
  end

  describe "#handler404" do
    it "#returns Marten::Handlers::Defaults::PageNotFound by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.handler404.should eq Marten::Handlers::Defaults::PageNotFound
    end

    it "returns the configured handler class if explictely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.handler404 = Marten::Conf::GlobalSettingsSpec::TestHandler
      global_settings.handler404.should eq Marten::Conf::GlobalSettingsSpec::TestHandler
    end
  end

  describe "#handler404=" do
    it "allows to configure the handler class used for not found responses" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.handler404 = Marten::Conf::GlobalSettingsSpec::TestHandler
      global_settings.handler404.should eq Marten::Conf::GlobalSettingsSpec::TestHandler
    end
  end

  describe "#handler500" do
    it "#returns Marten::Handlers::Defaults::ServerError by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.handler500.should eq Marten::Handlers::Defaults::ServerError
    end

    it "returns the configured handler class if explictely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.handler500 = Marten::Conf::GlobalSettingsSpec::TestHandler
      global_settings.handler500.should eq Marten::Conf::GlobalSettingsSpec::TestHandler
    end
  end

  describe "#handler500=" do
    it "allows to configure the handler class used for server error responses" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.handler500 = Marten::Conf::GlobalSettingsSpec::TestHandler
      global_settings.handler500.should eq Marten::Conf::GlobalSettingsSpec::TestHandler
    end
  end

  describe "#with_target_env" do
    it "allows to temporarily persist the configured env" do
      settings = Marten::Conf::GlobalSettingsSpec::TestGlobalSettings.new

      settings.target_env.should be_nil

      settings.with_target_env("test") do |s1|
        s1.target_env.should eq "test"

        s1.with_target_env("production") do |s2|
          s2.target_env.should eq "production"
        end

        s1.target_env.should eq "test"
      end

      settings.target_env.should be_nil
    end
  end

  describe "#x_frame_options" do
    it "#returns DENY by default" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.x_frame_options.should eq "DENY"
    end

    it "returns the configured X-Frame-Options header value if explicitely set" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.x_frame_options = "SAMEORIGIN"
      global_settings.x_frame_options.should eq "SAMEORIGIN"
    end
  end

  describe "#x_frame_options=" do
    it "allows to configure the X-Frame-Options header value with a string" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.x_frame_options = "SAMEORIGIN"
      global_settings.x_frame_options.should eq "SAMEORIGIN"
    end

    it "allows to configure the X-Frame-Options header value with a symbol" do
      global_settings = Marten::Conf::GlobalSettings.new
      global_settings.x_frame_options = :SAMEORIGIN
      global_settings.x_frame_options.should eq "SAMEORIGIN"
    end
  end
end

module Marten::Conf::GlobalSettingsSpec
  class TestGlobalSettings < Marten::Conf::GlobalSettings
    getter target_env
  end

  class TestAppConfig < Marten::App
    label :test
  end

  class TestHandler < Marten::Handlers::Base
    def get
      Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
    end
  end
end
