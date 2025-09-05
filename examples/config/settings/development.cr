Marten.configure :development do |config|
  # Enable debug mode for development
  config.debug = true

  # Enable live reload for development
  config.live_reload_enabled = true
  
  # Optional: customize live reload settings
  # config.live_reload_host = "localhost"    # Default
  # config.live_reload_port = 35729         # Default
  # config.live_reload_debounce = 1000      # Default: 1 second
  
  # Optional: customize file patterns to watch
  # config.live_reload_patterns = [
  #   "src/**/*.cr",
  #   "src/**/*.ecr",
  #   "src/assets/**/*",
  #   "config/**/*",
  # ]

  # Add the live reload middleware to the stack
  config.middleware = [
    Marten::Middleware::LiveReload.new,
    # ... other middleware ...
  ]

  # Other development settings...
end
