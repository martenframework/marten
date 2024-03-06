Marten.configure :test do |config|
  # Warning: the database used in the context of specs will be flushed and generated automatically every time the specs
  # suite is executed. Do not set these database names to the same names as the ones used for your development or
  # production environments.
  # If test database names are not explicitly set, your specs suite won't be allowed to run at all.
  config.database do |db| # ameba:disable Naming/BlockParameterName
    db.name = ":memory:"
  end

  config.allowed_hosts = ["127.0.0.1"]

  # Sets the global cache store to a "null store" to disable caching while still going through the caching interface.
  # https://martenframework.com/docs/caching/introduction#configuration-and-cache-stores
  config.cache_store = Marten::Cache::Store::Null.new

  # Collect sent emails to the standard output during tests for inspection purposes.
  # https://martenframework.com/docs/development/testing#collecting-emails
  config.emailing.backend = Marten::Emailing::Backend::Development.new(collect_emails: true, print_emails: false)
end
