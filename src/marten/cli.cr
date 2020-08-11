require "colorize"
require "option_parser"

require "./cli/**"

module Marten
  module CLI
    def self.run(options = ARGV)
      Command.new(options).run
    end
  end
end
