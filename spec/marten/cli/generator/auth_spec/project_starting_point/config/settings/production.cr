Marten.configure :production do |config|
  config.debug = false
  config.host = "0.0.0.0"
  config.port = 8000

  # Configure key settings through environment variables.
  config.secret_key = ENV.fetch("MARTEN_SECRET_KEY")

  # MARTEN_ALLOWED_HOSTS should be a comma-separated list (eg. "example.com, www.example.com").
  allowed_hosts = ENV.fetch("MARTEN_ALLOWED_HOSTS")
    .split(",")
    .map(&.strip)
    .reject(&.empty?)
  raise "MARTEN_ALLOWED_HOSTS cannot be empty" if allowed_hosts.empty?
  config.allowed_hosts = allowed_hosts

  # Secure session and CSRF cookies.
  config.sessions.cookie_secure = true
  config.sessions.cookie_http_only = true
  # Strict SameSite can break some cross-site flows. Adjust if needed.
  # config.sessions.cookie_same_site = "Strict"

  config.csrf.cookie_secure = true
  config.csrf.cookie_http_only = true
  # Strict SameSite can break some cross-site flows. Adjust if needed.
  # config.csrf.cookie_same_site = "Strict"

  # Enable template caching.
  config.templates.cached = true

  # If you're behind a proxy such as Caddy or Nginx, consider:
  # config.use_x_forwarded_host = true
  # config.use_x_forwarded_port = true
  # config.use_x_forwarded_proto = true

  # If you enable the SSL redirect middleware (Marten::Middleware::SSLRedirect):
  # config.ssl_redirect.host = "example.com"
  # config.ssl_redirect.exempted_paths = [/^\/healthz$/]

  # If you enable the HSTS middleware (Marten::Middleware::StrictTransportSecurity):
  # config.strict_transport_security.max_age = 31_536_000
  # config.strict_transport_security.include_sub_domains = true
  # config.strict_transport_security.preload = true

  # If you enable the CSP middleware (Marten::Middleware::ContentSecurityPolicy):
  # config.content_security_policy.default_src = [:self]
end
