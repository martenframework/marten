module Marten
  module CLI
    class Command
      @@command_registry = {} of ::String => Base.class

      def self.register_subcommand(command_klass : Base.class)
        @@command_registry[command_klass.command_name] = command_klass
      end

      def initialize(@options : Array(String), @name : String = Marten::CLI::DEFAULT_COMMAND_NAME)
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

        command = command_klass.not_nil!.new(options, main_command_name: @name)
        command.handle
      end

      private USAGE_HEADER = <<-USAGE_HEADER
        Usage: %s [command] [arguments]

        Available commands:


        USAGE_HEADER

      private USAGE_FOOTER = <<-USAGE_FOOTER
        Run a command followed by --help to see command specific information, ex:
        manage <command> --help

        USAGE_FOOTER

      private getter options

      private def show_top_level_usage
        usage = [] of String

        usage << USAGE_HEADER % @name

        per_app_commands = @@command_registry.values.group_by do |command|
          command.dir_location.starts_with?(__DIR__) ? "marten" : command.app_config.label
        end

        per_app_commands.each do |app_label, commands|
          usage << "[#{app_label}]\n".colorize(:green).to_s
          commands.each do |command|
            usage << "  › #{command.command_name}\n"
          end
          usage << "\n"
        end

        usage << USAGE_FOOTER

        puts usage.join("")
      end
    end
  end
end
