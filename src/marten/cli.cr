module Marten
  module CLI
    def self.run(options = ARGV)
      Command.new(options).run
    end
  end
end
