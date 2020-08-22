require "./test_project/**"

Marten.configure do |config|
  config.secret_key = "dummy"

  {% if env("MARTEN_SPEC_DB_CONNECION").id == "postgresql" %}
    raise NotImplementedError.new("Test PostgreSQL connection should be configured here!")
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
