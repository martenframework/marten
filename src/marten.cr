# Marten - The pragmatic web framework.

require "compress/gzip"
require "compress/zlib"
require "crypto/subtle"
require "db"
require "digest/md5"
require "ecr/macros"
require "file_utils"
require "html"
require "http"
require "i18n"
require "log"
require "mime/media_type"
require "msgpack"
require "openssl/hmac"
require "option_parser"
require "uuid"

require "./marten/app"
require "./marten/apps/*"
require "./marten/asset/**"
require "./marten/cache/**"
require "./marten/conf/**"
require "./marten/core/**"
require "./marten/db"
require "./marten/email"
require "./marten/emailing/**"
require "./marten/ext/**"
require "./marten/handler"
require "./marten/handlers/**"
require "./marten/http/**"
require "./marten/middleware"
require "./marten/middleware/**"
require "./marten/model"
require "./marten/routing/**"
require "./marten/schema"
require "./marten/server"
require "./marten/server/**"
require "./marten/template/**"

module Marten
  VERSION = "0.4.0"

  Log = ::Log.for("marten")

  @@apps : Apps::Registry?
  @@media_files_storage : Core::Storage::Base?
  @@env : Conf::Env?
  @@routes : Routing::Map?
  @@settings : Conf::GlobalSettings?

  # Returns the apps registry.
  #
  # This method returns an instance of `Marten::Apps::Registry`, giving access to the details of the installed
  # applications.
  def self.apps
    @@apps ||= Apps::Registry.new
  end

  # Returns the assets engine.
  #
  # This method returns an instance of `Marten::Asset::Engine`, which allows to find assets and to generate their URLs.
  def self.assets
    @@assets.not_nil!
  end

  # Returns the global cache store.
  #
  # This method returns a `Marten::Cache::Store::Base` object that can be interacted with to store string values in a
  # global cache.
  def self.cache : Cache::Store::Base
    # def self.cache : Cache::Store
    settings.cache_store
  end

  # Allows to configure a Marten project.
  #
  # This method allows to define the setting values of a Marten project. When called without argument, it allows to
  # define shared setting values (ie. shared across all environments):
  #
  # ```
  # Marten.configure do |config|
  #   config.installed_apps = [
  #     FooApp,
  #     BarApp,
  #   ]
  # end
  # ```
  #
  # This method can also be called with a specific argument in order to ensure that the underlying settings are defined
  # for a specific environment only:
  #
  # ```
  # Marten.configure :development do |config|
  #   config.secret_key = "INSECURE"
  # end
  # ```
  def self.configure(env : Nil | String | Symbol = nil, &)
    return unless env.nil? || self.env == env.to_s
    settings.with_target_env(env.try(&.to_s)) { |settings_with_target_env| yield settings_with_target_env }
  end

  # Returns the current Marten environment.
  #
  # This method returns a `Marten::Conf::Env` object, which allows to interact with the current environment. For
  # example:
  #
  # ```
  # Marten.env              # => <Marten::Conf::Env:0x1052b8060 @id="development">
  # Marten.env.id           # => "development"
  # Marten.env.development? # => true
  # ```
  def self.env
    @@env ||= Conf::Env.new
  end

  # Returns the media files storage.
  #
  # This method returns an instance of a `Marten::Core::Storage::Base` subclass. This object allows to perform file
  # operations like saving files, deleting files, generating URLs...
  def self.media_files_storage
    @@media_files_storage.not_nil!
  end

  # Returns the main routes map.
  #
  # This method returns the main routes map, initialized according to the routes configuration and allowing to perform
  # reverse URL resolutions.
  def self.routes
    @@routes ||= Routing::Map.new
  end

  # Returns the settings of the application.
  #
  # This method returns the main `Marten::Conf::GlobalSettings` object, which contains the settings configured for the
  # current environment.
  def self.settings
    @@settings ||= Conf::GlobalSettings.new
  end

  # Setups the Marten project.
  #
  # This involves setup-ing the configured settings, applications, assets, templates, and the I18n tooling.
  def self.setup
    setup_settings
    setup_apps
    setup_assets
    setup_media_files
    setup_templates
    setup_i18n
  end

  # :nodoc:
  def self.setup_apps : Nil
    apps.populate(settings.installed_apps)
    apps.insert_main_app
    apps.setup
  end

  # :nodoc:
  def self.setup_assets : Nil
    @@assets = Asset::Engine.new(
      storage: (
        settings.assets.storage ||
        Core::Storage::FileSystem.new(root: settings.assets.root, base_url: settings.assets.url)
      )
    )

    finders = [] of Asset::Finder::Base
    finders << Asset::Finder::AppDirs.new if settings.assets.app_dirs
    finders += settings.assets.dirs.map { |d| Asset::Finder::FileSystem.new(d) }

    assets.manifests = settings.assets.manifests

    assets.finders = finders
  end

  # :nodoc:
  def self.setup_media_files : Nil
    @@media_files_storage = (
      settings.media_files.storage ||
      Core::Storage::FileSystem.new(root: settings.media_files.root, base_url: settings.media_files.url)
    )
  end

  # :nodoc:
  def self.setup_settings : Nil
    settings.setup
  end

  # :nodoc:
  def self.setup_templates : Nil
    @@templates = Template::Engine.new

    loaders = [] of Marten::Template::Loader::Base
    loaders << Template::Loader::AppDirs.new if settings.templates.app_dirs
    loaders += settings.templates.dirs.map { |d| Template::Loader::FileSystem.new(d) }

    templates.loaders = if settings.templates.cached
                          [Template::Loader::Cached.new(loaders)] of Marten::Template::Loader::Base
                        else
                          loaders
                        end

    context_producers = [] of Marten::Template::ContextProducer
    context_producers += settings.templates.context_producers.map(&.new)
    templates.context_producers = context_producers
  end

  # :nodoc:
  def self.setup_i18n : Nil
    I18n.config.default_locale = settings.i18n.default_locale
    I18n.config.available_locales = settings.i18n.available_locales

    # Add Marten's built-in translations first.
    I18n.config.loaders << I18n::Loader::YAML.new("#{effective_marten_location}/marten/locales")

    # Ensure each app config translation loader is properly bound to the I18n config.
    I18n.config.loaders += apps.app_configs.compact_map(&.translations_loader)

    I18n.init
  end

  # Starts the Marten server.
  def self.start(host : String? = nil, port : Int32? = nil, args : Array(String) = ARGV)
    parse_start_args(args)
    override_server_host(host) if host
    override_server_port(port) if port

    setup

    Marten::Server.setup

    Log.info { "Marten running on #{Marten::Server.addresses.join ", "} (Press CTRL+C to quit)" }

    Signal::INT.trap do
      Signal::INT.reset
      Log.info { "Shutting down" }
      Marten::Server.stop
    end

    Marten::Server.start
  end

  # Returns the Marten templates engine.
  #
  # This method returns an instance of `Marten::Template::Engine`, which allows to find templates and to render them.
  def self.templates
    @@templates.not_nil!
  end

  # :nodoc:
  def self._marten_app_location : String
    __DIR__
  end

  private def self.effective_marten_location : String
    if !(root_path = Marten.settings.root_path).nil?
      Path[_marten_app_location]
        .relative_to(Path[Marten::Apps::Config.compilation_root_path])
        .expand(root_path)
        .to_s
    else
      _marten_app_location
    end
  end

  private def self.override_server_host(host : String)
    Marten.settings.host = host
  end

  private def self.override_server_port(port : Int32)
    Marten.settings.port = port.to_i
  end

  private def self.parse_start_args(args : Array(String))
    OptionParser.parse(args) do |opts|
      opts.on("-b HOST", "--bind HOST", "Custom host to bind") do |host|
        override_server_host(host.strip)
      end
      opts.on("-p PORT", "--port PORT", "Custom port to listen for connections") do |port|
        override_server_port(port.to_i)
      end
      opts.on("-h", "--help", "Shows this help") do
        puts opts
        exit 0
      end
    end
  end
end
