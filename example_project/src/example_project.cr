require "../../src/marten"

require "./apps/admin/*"
require "./apps/blog/*"
require "./apps/blog/views/*"

require "../config/routes"
require "../config/settings/*"

Marten.start
