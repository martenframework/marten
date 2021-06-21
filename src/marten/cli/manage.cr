module Marten
  module CLI
    # The manage CLI.
    #
    # The manage (or management) CLI allows developers to interact with their Marten projects by issuing sub-commands.
    # These sub-commands are either "built-in" (Marten comes with a predefined set of commands to handle various things
    # such as database management, projects / apps initializations, etc), or they are provided by installed apps.
    class Manage
      @@command_registry = [] of Command::Base.class

      @commands_per_name : Hash(String, Command::Base.class)

      # Allows to register a new command in order to make it available to the management CLI.
      def self.register_subcommand(command_klass : Command::Base.class)
        @@command_registry << command_klass
      end

      def initialize(
        @options : Array(String),
        @stdout : IO = STDOUT,
        @stderr : IO = STDERR,
        @name : String = Marten::CLI::DEFAULT_COMMAND_NAME
      )
        @commands_per_name = Hash(String, Command::Base.class).new
        @@command_registry.each { |k| @commands_per_name[k.command_name] = k }
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

        command_klass = @commands_per_name.fetch(command) do
          stderr.puts("Unknown command")
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
        %s [command] --help

        USAGE_FOOTER

      private getter options
      private getter stdout
      private getter stderr

      private def show_top_level_usage
        usage = [] of String

        usage << USAGE_HEADER % @name

        per_app_commands = @commands_per_name.values.group_by do |command|
          command._marten_app_location.starts_with?(__DIR__) ? "marten" : command.app_config.label
        end

        per_app_commands.each do |app_label, commands|
          usage << "[#{app_label}]\n".colorize(:green).to_s
          commands.each do |command|
            usage << "  › #{command.command_name}\n"
          end
          usage << "\n"
        end

        usage << USAGE_FOOTER % @name

        stdout.puts(usage.join(""))
      end
    end
  end
end
