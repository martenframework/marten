Marten.configure do |config|
  config.secret_key = "dummy"

  config.installed_apps = [
    # Marten::Contrib::Admin,
    # ExampleProject,
    # ExampleProject::Apps::Blog,
    # ExampleProject::Apps::Comment,
    Admin::App,
    Blog::App,
  ]

  config.database do |db|
    db.backend = :sqlite
    db.name = "development.db"
  end

  config.blog.foo = "bar"
end
