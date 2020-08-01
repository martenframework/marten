module Marten
  module CLI
    class Command
      USAGE_HEADER = <<-USAGE_HEADER
        Usage: manage [command] [arguments]

        Available commands:

        USAGE_HEADER

      USAGE_FOOTER = <<-USAGE_FOOTER
        Run a command followed by --help to see command specific information, ex:
        manage <command> --help

        USAGE_FOOTER

      @@command_registry = {} of ::String => Base.class

      def self.register_subcommand(command_klass : Base.class)
        @@command_registry[command_klass.command_name] = command_klass
      end

      def self.run(options = ARGV)
        new(options).run
      end

      def initialize(@options : Array(String))
      end

      def run
        command = options.first?

        unless command
          show_top_level_usage
          exit
        end

        if command == "--help" || command == "-h"
          show_top_level_usage
          exit
        end

        command_klass = @@command_registry.fetch(command) do
          puts "Unknown command"
          exit
        end

        options.shift

        command = command_klass.not_nil!.new(options)
        command.handle
      end

      private getter options

      private def show_top_level_usage
        usage = [] of String

        usage << USAGE_HEADER

        per_app_commands = @@command_registry.values.group_by do |command|
          command.dir_location.starts_with?(__DIR__) ? "marten" : command.app_config.label
        end

        per_app_commands.each do |app_label, commands|
          usage << "\n[#{app_label}]\n"
          commands.each do |command|
            usage << "    #{command.command_name}\n"
          end
          usage << "\n"
        end

        usage << USAGE_FOOTER

        puts usage.join("")
      end
    end
  end
end
