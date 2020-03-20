# Marten - The pragmatic web framework.

require "logger"
require "http"
require "uuid"

require "./marten/*"
require "./marten/conf/**"
require "./marten/http/**"
require "./marten/routing/**"
require "./marten/server/**"
require "./marten/views/**"

module Marten
  @@env : Conf::Env?
  @@routes : Routing::Map?
  @@settings : Conf::Settings?

  def self.setup
    settings.setup
  end

  def self.start
    setup
    Marten::Server.run
  end

  def self.configure(env : Nil | String | Symbol = nil)
    return unless env.nil? || self.env == env.to_s
    with settings yield settings
  end

  def self.env
    @@env ||= Conf::Env.new
  end

  def self.logger
    settings.logger
  end

  def self.settings
    @@settings ||= Conf::Settings.new
  end

  def self.routes
    @@routes ||= Routing::Map.new
  end
end
