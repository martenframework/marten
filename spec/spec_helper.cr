ENV["MARTEN_ENV"] = "test"

require "spec"

require "json"

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
