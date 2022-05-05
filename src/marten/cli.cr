require "colorize"
require "ecr"
require "option_parser"

require "./cli/**"

module Marten
  module CLI
    DEFAULT_COMMAND_NAME = "marten"

    def self.run(options = ARGV, name = DEFAULT_COMMAND_NAME)
      Manage.new(options: options, name: name).run
    end
  end
end
