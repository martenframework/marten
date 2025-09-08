Marten.configure :development do |config|
  # Enable debug mode for development
  config.debug = true

  # Enable live reload for development
  config.live_reload_enabled = true

  # Optional: customize file patterns to watch
  config.live_reload_patterns = [
    "src/**/*.cr",
    "src/**/*.ecr",
    "src/**/*.html",
    "src/assets/**/*",
    "config/**/*",
  ]

  # Add the live reload middleware to the stack
  config.middleware = [
    Marten::LiveReload,
    # ... other middleware ...
  ]

  # Other development settings...
end
