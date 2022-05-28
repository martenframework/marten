# Marten - The pragmatic web framework.

require "db"
require "compress/gzip"
require "crypto/subtle"
require "digest/md5"
require "ecr/macros"
require "file_utils"
require "html"
require "http"
require "i18n"
require "log"
require "mime/media_type"
require "openssl/hmac"
require "uuid"

require "./marten/app"
require "./marten/apps/*"
require "./marten/asset/**"
require "./marten/conf/**"
require "./marten/core/**"
require "./marten/db/**"
require "./marten/ext/**"
require "./marten/http/**"
require "./marten/middleware"
require "./marten/middleware/**"
require "./marten/migration"
require "./marten/model"
require "./marten/routing/**"
require "./marten/schema"
require "./marten/server"
require "./marten/server/**"
require "./marten/template/**"
require "./marten/view"
require "./marten/views/**"

module Marten
  VERSION = "0.1.0.dev0"

  Log = ::Log.for("marten")

  @@apps : Apps::Registry?
  @@media_files_storage : Core::Storage::Base?
  @@env : Conf::Env?
  @@routes : Routing::Map?
  @@settings : Conf::GlobalSettings?

  def self.apps
    @@apps ||= Apps::Registry.new
  end

  def self.assets
    @@assets.not_nil!
  end

  def self.configure(env : Nil | String | Symbol = nil)
    return unless env.nil? || self.env == env.to_s
    settings.with_target_env(env.try(&.to_s)) { |settings_with_target_env| yield settings_with_target_env }
  end

  def self.env
    @@env ||= Conf::Env.new
  end

  def self.media_files_storage
    @@media_files_storage.not_nil!
  end

  def self.routes
    @@routes ||= Routing::Map.new
  end

  # Returns the settings of the application.
  #
  # This method returns the main `Marten::Conf::GlobalSettings` object containing the settings configured for the
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
  end

  # :nodoc:
  def self.setup_i18n : Nil
    I18n.config.default_locale = settings.i18n.default_locale
    I18n.config.available_locales = settings.i18n.available_locales

    # Add Marten's built-in translations first.
    I18n.config.loaders << I18n::Loader::YAML.new("#{__DIR__}/marten/locales")

    # Ensure each app config translation loader is properly bound to the I18n config.
    I18n.config.loaders += apps.app_configs.compact_map(&.translations_loader)

    I18n.init
  end

  def self.start
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

  def self.templates
    @@templates.not_nil!
  end

  protected def self.dir_location
    __DIR__
  end
end
