# Marten - The pragmatic web framework.

require "db"
require "log"
require "http"
require "uuid"

require "./marten/apps/**"
require "./marten/conf/**"
require "./marten/core/**"

require "./marten/db/connection"
require "./marten/db/connection/**"
require "./marten/db/field"
require "./marten/db/field/**"
require "./marten/db/errors"
require "./marten/db/expression/**"
require "./marten/db/model"
require "./marten/db/model/**"
require "./marten/db/query_node"
require "./marten/db/query_set"
require "./marten/db/sql/**"

require "./marten/ext/**"
require "./marten/http/**"
require "./marten/routing/**"
require "./marten/server"
require "./marten/server/**"
require "./marten/views/**"

module Marten
  VERSION = "0.1.0.dev0"

  Log = ::Log.for("marten")

  @@apps : Apps::Registry?
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
  end

  def self.configure(env : Nil | String | Symbol = nil)
    return unless env.nil? || self.env == env.to_s
    yield settings
  end

  def self.apps
    @@apps ||= Apps::Registry.new
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
end
