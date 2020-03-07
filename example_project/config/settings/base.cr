Marten.configure do |settings|
  settings.secret_key = "dummy"

  settings.installed_apps = [
    # Marten::Contrib::Admin,
    # ExampleProject,
    # ExampleProject::Apps::Blog,
    # ExampleProject::Apps::Comment,
    Admin::App,
    Blog::App,
  ]

  settings.database do |config|
    config.backend = :sqlite
    config.name = "development.db"
  end
end
