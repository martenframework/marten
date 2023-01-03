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

# Empty media directory after specs execution.
Spec.after_suite { Dir["spec/media/*"].each { |d| FileUtils.rm_rf(d) } }

def for_mysql(&)
  for_db_backends(:mysql) do
    yield
  end
end

def for_postgresql(&)
  for_db_backends(:postgresql) do
    yield
  end
end

def for_sqlite(&)
  for_db_backends(:sqlite) do
    yield
  end
end

def for_db_backends(*backends : String | Symbol, &)
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

macro with_overridden_setting(setting_name, setting_value, nilable = false)
  begin
    {% old_setting_var_name = "old_#{setting_name.gsub(/\./, "_").id}_value" %}
    {{ old_setting_var_name.id }} = Marten.settings.{{ setting_name.id }}
    Marten.settings.{{ setting_name.id }} = {{ setting_value }}
    {{ yield }}
  ensure
    {% old_setting_var_name = "old_#{setting_name.gsub(/\./, "_").id}_value" %}
    Marten.settings.{{ setting_name.id }} = {{ old_setting_var_name.id }}{% unless nilable %}.not_nil!{% end %}
  end
end
