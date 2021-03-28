# Marten - The pragmatic web framework.

require "crinja"
require "db"
require "http"
require "i18n"
require "log"
require "uuid"

require "./marten/app"
require "./marten/apps/**"
require "./marten/conf/**"
require "./marten/core/**"
require "./marten/db/**"
require "./marten/ext/**"
require "./marten/http/**"
require "./marten/middleware"
require "./marten/middleware/**"
require "./marten/model"
require "./marten/routing/**"
require "./marten/server"
require "./marten/server/**"
require "./marten/view"
require "./marten/views/**"

module Marten
  VERSION = "0.1.0.dev0"

  Log = ::Log.for("marten")

  @@apps : Apps::Registry?
  @@crinja : Crinja?
  @@env : Conf::Env?
  @@routes : Routing::Map?
  @@settings : Conf::GlobalSettings?

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

  def self.setup
    settings.setup
    apps.populate(settings.installed_apps)
    apps.setup
    setup_crinja
    setup_i18n
  end

  def self.setup_crinja : Nil
    @@crinja = Crinja.new

    loaders = [] of Crinja::Loader

    # Add per-app templates loaders first.
    loaders += apps.app_configs.compact_map(&.templates_loader) if settings.templates.app_dirs

    # Then generate any new templates loader based on the configured templates dirs.
    loaders += settings.templates.dirs.map { |d| Crinja::Loader::FileSystemLoader.new(d) }

    crinja.loader = Crinja::Loader::ChoiceLoader.new(loaders)
  end

  def self.setup_i18n : Nil
    I18n.config.default_locale = settings.i18n.default_locale
    I18n.config.available_locales = settings.i18n.available_locales

    # Add Marten's built-in translations first.
    I18n.config.loaders << I18n::Loader::YAML.new("#{__DIR__}/marten/locales")

    # Ensure each app config translation loader is properly bound to the I18n config.
    I18n.config.loaders += apps.app_configs.compact_map(&.translations_loader)

    I18n.init
  end

  def self.configure(env : Nil | String | Symbol = nil)
    return unless env.nil? || self.env == env.to_s
    settings.with_target_env(env.try(&.to_s)) { |settings_with_target_env| yield settings_with_target_env }
  end

  def self.apps
    @@apps ||= Apps::Registry.new
  end

  def self.crinja
    @@crinja.not_nil!
  end

  def self.env
    @@env ||= Conf::Env.new
  end

  # Returns the settings of the application.
  #
  # This method returns the main `Marten::Conf::GlobalSettings` object containing the settings configured for the
  # current environment.
  def self.settings
    @@settings ||= Conf::GlobalSettings.new
  end

  def self.routes
    @@routes ||= Routing::Map.new
  end

  protected def self.dir_location
    __DIR__
  end
end
