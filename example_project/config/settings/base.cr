Marten.configure do
  secret_key = "dummy"

  installed_apps = [
    # Marten::Contrib::Admin,
    # ExampleProject,
    # ExampleProject::Apps::Blog,
    # ExampleProject::Apps::Comment,
    Admin::App,
    Blog::App,
  ]

  database do
    backend = :sqlite
    name = "development.db"
  end
end
