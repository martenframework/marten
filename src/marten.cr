# Marten - The pragmatic web framework.

require "db"
require "log"
require "http"
require "uuid"

require "./marten/*"
require "./marten/conf/**"
require "./marten/db/**"
require "./marten/ext/**"
require "./marten/http/**"
require "./marten/routing/**"
require "./marten/server/**"
require "./marten/views/**"

module Marten
  VERSION = "0.1.0.dev0"

  Log = ::Log.for("marten")

  @@env : Conf::Env?
  @@routes : Routing::Map?
  @@settings : Conf::GlobalSettings?

  def self.setup
    settings.setup
  end

  def self.start
    setup
    Marten::Server.run
  end

  def self.configure(env : Nil | String | Symbol = nil)
    return unless env.nil? || self.env == env.to_s
    yield settings
  end

  def self.env
    @@env ||= Conf::Env.new
  end

  def self.settings
    @@settings ||= Conf::GlobalSettings.new
  end

  def self.routes
    @@routes ||= Routing::Map.new
  end
end
