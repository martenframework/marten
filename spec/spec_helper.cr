ENV["MARTEN_ENV"] = "test"

require "spec"

require "pg"
require "sqlite3"

require "../src/marten"
require "../src/marten/cli"
require "../src/marten/spec"

require "./test_project"
