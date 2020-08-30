require "./test_project/**"

ENV_SETTINGS_FILENAME = ".spec.env.json"

if File.exists?(ENV_SETTINGS_FILENAME)
  env_settings = Hash(String, Int32 | String).from_json(File.read(ENV_SETTINGS_FILENAME))
else
  env_settings = Hash(String, Int32 | String).new
end

Marten.configure do |config|
  config.secret_key = "dummy"

  config.installed_apps = [
    TestApp,
  ]

  {% if env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
    config.database do |db|
      db.backend = :postgresql
      db.name = env_settings["POSTGRESQL_DB_NAME"].as(String)
      db.user = env_settings["POSTGRESQL_DB_USER"].as(String)
      db.password = env_settings["POSTGRESQL_DB_PASSWORD"].as(String)
      db.host = env_settings["POSTGRESQL_DB_HOST"].as(String)
    end
  {% else %}
    # Default to an in-memory SQLite.
    config.database do |db|
      db.backend = :sqlite
      db.name = ":memory:"
    end
  {% end %}
end

Marten.routes.draw do
  path "/dummy", DummyView, name: "dummy"
  path "/dummy/<id:int>", DummyView, name: "dummy_with_id"
end
