ENV["MARTEN_ENV"] = "test"

require "json"
require "spec"
require "timecop"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
  require "pg"
{% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
  require "mysql"
{% else %}
  require "sqlite3"
{% end %}

require "../src/marten"
require "../src/marten/cli"
require "../src/marten/spec"

require "./ext/**"
require "./test_project"

def for_mysql(&block)
  for_db_backends(:mysql) do
    yield
  end
end

def for_postgresql(&block)
  for_db_backends(:postgresql) do
    yield
  end
end

def for_sqlite(&block)
  for_db_backends(:sqlite) do
    yield
  end
end

def for_db_backends(*backends : String | Symbol, &block)
  current_db_backend = ENV["MARTEN_SPEC_DB_CONNECTION"]? || "sqlite"
  if backends.map(&.to_s).includes?(current_db_backend)
    yield
  end
end

macro with_installed_apps(*apps)
  around_each do |t|
    original_app_configs_store = Marten.apps.app_configs_store

    Marten.apps.app_configs_store = {} of String => Marten::Apps::Config
    Marten.apps.populate(Marten.settings.installed_apps + {{ apps }}.to_a)
    Marten::Spec.setup_databases

    t.run

    Marten::Spec.flush_databases
    Marten.apps.app_configs_store = original_app_configs_store
  end
end
