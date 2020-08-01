module Marten
  module CLI
    class Command
      abstract class Base
        macro inherited
          Command.register_subcommand({{ @type }})
        end

        # :nodoc:
        record ArgumentHandler, name : String, block : String ->

        @@command_name : String = ""
        @@help : String = ""

        class_getter help

        def self.command_name
          return @@command_name unless @@command_name.empty?
          @@command_name = name.split("::").last.underscore
        end

        def self.help(help : String)
          @@help = help
        end

        @arguments = [] of String
        @argument_handlers = [] of ArgumentHandler
        @parser : OptionParser?

        def initialize(@options : Array(String))
        end

        def setup
        end

        def run
        end

        protected def handle
          @parser = OptionParser.new

          setup

          parser.on("-h", "--help", "Show this help") do
            puts parser
            exit
          end

          parser.banner = banner_parts.join("")

          parser.unknown_args do |args, _args_after_two_dashes|
            args.each_with_index do |arg, i|
              handler = argument_handlers[i]?
              error("Unrecognized argument: #{arg}") if handler.nil?
              handler.block.call(arg)
            end
          end

          parser.parse(options)

          run
        end

        private getter arguments
        private getter argument_handlers
        private getter options

        private def parser
          @parser.not_nil!
        end

        private def banner_parts
          banner_parts = [] of String
          banner_parts << "Usage: manage #{self.class.command_name} [options]\n\n"
          banner_parts << "#{self.class.help}\n\n" unless self.class.help.empty?

          unless arguments.empty?
            banner_parts << "Arguments:\n"
            banner_parts << arguments.join("\n")
            banner_parts << "\n\n"
          end

          banner_parts << "Options:"
        end

        private def on_argument(name : String | Symbol, description : String, &block : String ->)
          name = name.to_s
          # TODO: validate name format
          append_argument(name, description)
          @argument_handlers << ArgumentHandler.new(name, block)
        end

        private def on_option(flag : String | Symbol, description : String, &block : String ->)
          flag = flag.to_s
          # TODO: validate flag format
          parser.on("--#{flag}", description, &block)
        end

        private def on_option(
          short_flag : String | Symbol,
          long_flag : String | Symbol,
          description : String,
          &block : String ->
        )
          short_flag = short_flag.to_s
          long_flag = long_flag.to_s
          # TODO: validate short_flag and long_flag format
          parser.on("-#{short_flag}", "--#{long_flag}", description, &block)
        end

        private def append_argument(name, description)
          if name.size >= 33
            @arguments << "    #{name}\n#{" " * 37}#{description}"
          else
            @arguments << "    #{name}#{" " * (33 - name.size)}#{description}"
          end
        end

        private def error(msg, exit_code = 1)
          puts msg
          exit(exit_code)
        end
      end
    end
  end
end
