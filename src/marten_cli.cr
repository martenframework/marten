require "./marten"
require "./marten/cli"

Marten::CLI::Admin.new(options: ARGV).run
