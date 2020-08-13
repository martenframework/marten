require "colorize"
require "option_parser"

require "./cli/**"

module Marten
  module CLI
    DEFAULT_COMMAND_NAME = "manage"

    def self.run(options = ARGV, name = DEFAULT_COMMAND_NAME)
      Command.new(options, name).run
    end
  end
end
