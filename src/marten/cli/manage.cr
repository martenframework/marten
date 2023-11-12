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

      # :nodoc:
      def self.registry : Array(Command::Base.class)
        @@command_registry
      end

      def initialize(
        @options : Array(String),
        @stdout : IO = STDOUT,
        @stderr : IO = STDERR,
        @name : String = Marten::CLI::DEFAULT_COMMAND_NAME
      )
        @commands_per_name = Hash(String, Command::Base.class).new

        @@command_registry.each do |command_klass|
          @commands_per_name[command_klass.command_name] = command_klass

          command_klass.command_aliases.each do |command_alias|
            @commands_per_name[command_alias] = command_klass
          end
        end
      end

      def run
        command = options.first?

        unless command
          show_top_level_usage
          exit
        end

        if command == "--help" || command == "-h" || (command == "help" && options.size == 1)
          show_top_level_usage
          exit
        end

        if command == "help"
          command = options[1]
          options.shift
          options << "--help"
        end

        if command == "--version" || command == "-v"
          show_version
          exit
        end

        command_klass = @commands_per_name.fetch(command) do
          stderr.puts("Unknown command")
          exit
        end

        options.shift

        command = command_klass.not_nil!.new(options, main_command_name: @name)
        command.handle!
      end

      private USAGE_HEADER = <<-USAGE_HEADER
        Usage: %s [command] [options] [arguments]

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

        full_command_name = ->(command : Command::Base.class) {
          ([command.command_name] + command.command_aliases).join(" / ")
        }

        longest_command_name = @commands_per_name.values.max_of { |command| full_command_name.call(command).size }

        description_padding = ->(command_name : String) { " " * (longest_command_name - command_name.size + 2) }

        per_app_commands = @commands_per_name.values.group_by do |command|
          command._marten_app_location.starts_with?(__DIR__) ? "marten" : command.app_config.label
        end

        per_app_commands.each do |app_label, commands|
          usage << "[#{app_label}]\n\n".colorize(:green).to_s
          commands.uniq.each do |command|
            usage << "  › ".colorize(:green).to_s

            usage << ([command.command_name] + command.command_aliases)
              .map(&.colorize(:yellow).to_s)
              .join(" / ".colorize(:dark_gray).to_s)

            usage << description_padding.call(full_command_name.call(command))
            usage << command.help

            usage << "\n"
          end
          usage << "\n"
        end

        usage << USAGE_FOOTER % @name

        stdout.puts(usage.join(""))
      end

      private def show_version
        Manage::Command::Version.new(options: [] of String, stdout: stdout, stderr: stderr).handle!
      end
    end
  end
end
