# Third party requirements.
require "marten"
require "sqlite3"

# Configuration requirements.
require "../config/routes"
require "../config/settings/base"
require "../config/settings/**"
require "../config/initializers/**"

# Project requirements.
require "./handlers/**"
require "./models/**"
require "./schemas/**"
