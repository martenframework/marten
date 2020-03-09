# Marten - The pragmatic web framework.

require "http"

require "./marten/*"
require "./marten/conf/**"
require "./marten/http/**"
require "./marten/server/**"
require "./marten/views/**"

module Marten
  @@env : Conf::Env?
  @@routes : Conf::Routing::Map?
  @@settings : Conf::Settings?

  def self.start
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
    @@settings ||= Conf::Settings.new
  end

  def self.routes
    @@routes ||= Conf::Routing::Map.new
  end
end
