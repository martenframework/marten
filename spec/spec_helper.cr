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
