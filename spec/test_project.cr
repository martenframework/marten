require "./test_project/**"

ENV_SETTINGS_FILENAME = ".spec.env.json"

if File.exists?(ENV_SETTINGS_FILENAME)
  env_settings = Hash(String, Int32 | String).from_json(File.read(ENV_SETTINGS_FILENAME))
else
  env_settings = Hash(String, Int32 | String).new
end

Marten.configure :test do |config|
  config.secret_key = "__insecure_#{Random::Secure.random_bytes(32).hexstring}__"
  config.log_level = ::Log::Severity::None

  config.installed_apps = [
    TestApp,
  ]

  for_mysql do
    config.database do |db|
      db.backend = :mysql
      db.name = env_settings["MYSQL_DEFAULT_DB_NAME"].as(String)
      db.user = env_settings["MYSQL_DB_USER"].as(String)
      db.password = env_settings["MYSQL_DB_PASSWORD"].as(String)
      db.host = env_settings["MYSQL_DB_HOST"].as(String)
    end

    config.database :other do |db|
      db.backend = :mysql
      db.name = env_settings["MYSQL_OTHER_DB_NAME"].as(String)
      db.user = env_settings["MYSQL_DB_USER"].as(String)
      db.password = env_settings["MYSQL_DB_PASSWORD"].as(String)
      db.host = env_settings["MYSQL_DB_HOST"].as(String)
    end
  end

  for_postgresql do
    config.database do |db|
      db.backend = :postgresql
      db.name = env_settings["POSTGRESQL_DEFAULT_DB_NAME"].as(String)
      db.user = env_settings["POSTGRESQL_DB_USER"].as(String)
      db.password = env_settings["POSTGRESQL_DB_PASSWORD"].as(String)
      db.host = env_settings["POSTGRESQL_DB_HOST"].as(String)
    end

    config.database :other do |db|
      db.backend = :postgresql
      db.name = env_settings["POSTGRESQL_OTHER_DB_NAME"].as(String)
      db.user = env_settings["POSTGRESQL_DB_USER"].as(String)
      db.password = env_settings["POSTGRESQL_DB_PASSWORD"].as(String)
      db.host = env_settings["POSTGRESQL_DB_HOST"].as(String)
    end
  end

  for_sqlite do
    config.database do |db|
      db.backend = :sqlite
      db.name = ":memory:"
    end

    config.database :other do |db|
      db.backend = :sqlite
      db.name = ":memory:"
    end
  end

  config.middleware = [
    Marten::Middleware::Session,
    Marten::Middleware::Flash,
    Marten::Middleware::GZip,
  ]

  config.templates.app_dirs = true
  config.templates.dirs = [
    "test_project/templates",
  ]

  config.assets.root = "spec/assets"
  config.media_files.root = "spec/media"
end

Marten.routes.draw do
  path "/dummy", DummyHandler, name: "dummy"
  path "/dummy/<id:int>", DummyHandler, name: "dummy_with_id"
  path "/dummy/<id:int>/and/<scope:slug>", DummyHandler, name: "dummy_with_id_and_scope"
  path "/request-method-respond", RequestMethodRespondHandler, name: "request_method_respond"
  path "/query-params-respond", QueryParamsRespondHandler, name: "query_params_respond"
  path "/headers-respond", HeadersRespondHandler, name: "headers_respond"
  path "/secure-request-require", SecureRequestRequireHandler, name: "secure_request_require"
  path "/session-value-get", SessionValueGetHandler, name: "session_value_get"
  path "/session-value-set", SessionValueSetHandler, name: "session_value_set"
  path "/cookie-value-get", CookieValueGetHandler, name: "cookie_value_get"
  path "/cookie-value-set", CookieValueSetHandler, name: "cookie_value_set"
  path "/simple-schema", SimpleSchemaHandler, name: "simple_schema"
  path "/simple-file-schema", SimpleFileSchemaHandler, name: "simple_file_schema"
end
