module Marten
  module CLI
    class Manage
      module Command
        # Management abstract command.
        #
        # This class should be subclassed in order to implement per-app management commands. Subclasses will be
        # automatically registered to the management commands registry, and they will be made available through the
        # `manage` CLI.
        abstract class Base
          include Apps::Association

          macro inherited
            Marten::CLI::Manage.register_subcommand({{ @type }})
          end

          # :nodoc:
          record ArgumentHandler, name : String, block : String ->

          @@app_config : Marten::Apps::Config?
          @@command_aliases = [] of String
          @@command_name : String = ""
          @@help : String = ""

          # Returns the aliases of the command.
          class_getter command_aliases

          # Returns the help description of the command.
          class_getter help

          # Returns the `IO` object that should be used by the command as the main error file descriptor.
          getter stderr

          # Returns the `IO` object that should be used by the command as the main input file descriptor.
          getter stdin

          # Returns the `IO` object that should be used by the command as the main output file descriptor.
          getter stdout

          # Allows to configure aliases for the command.
          def self.command_aliases(*aliases : String | Symbol)
            @@command_aliases += aliases.map(&.to_s).to_a
          end

          # Returns the name of the considered command.
          def self.command_name
            return @@command_name unless @@command_name.empty?
            @@command_name = name.split("::").last.underscore
          end

          # Allows to set the name of the command.
          #
          # The value set using this method will be used by users when they invoke the command through the use of the
          # `manage` CLI.
          def self.command_name(name : String | Symbol)
            @@command_name = name.to_s
          end

          # Allows to set the help description of the command.
          def self.help(help : String)
            @@help = help
          end

          protected def self.app_config
            @@app_config ||= Marten.apps.get_containing(self)
          end

          @arguments = [] of String
          @argument_handlers = [] of ArgumentHandler
          @color = true
          @parser : OptionParser?
          @show_error_trace = false

          def initialize(
            @options : Array(String),
            @stdin : IO = STDIN,
            @stdout : IO = STDOUT,
            @stderr : IO = STDERR,
            @main_command_name = Marten::CLI::DEFAULT_COMMAND_NAME
          )
            @parser = OptionParser.new
          end

          # Setups the command and runs it.
          #
          # This method will call the `#setup` method, configure the arguments / options parser and then execute the
          # command through the use of the `#run` method.
          def handle
            setup

            parser.on("--error-trace", "Show full error trace (if a compilation is involved)") do
              @show_error_trace = true
            end

            parser.on("--no-color", "Disable colored output") do
              @color = false
            end

            parser.on("-h", "--help", "Show this help") do
              print(parser)
              exit
            end

            parser.banner = banner_parts.join("")

            parser.unknown_args do |args, _args_after_two_dashes|
              args.each_with_index do |arg, i|
                handler = argument_handlers[i]?
                print_error_and_exit("Unrecognized argument: #{arg}") if handler.nil?
                handler.block.call(arg)
              end
            end

            parser.invalid_option do |flag|
              print_error_and_exit("Unrecognized option: #{flag}")
            end

            parser.parse(options)

            run
          end

          # Allows to configure a specific command argument.
          #
          # This method will configure a command argument. It expects a name, a description, and it yields a block to
          # let the command properly assign the argument value to the command object:
          #
          # ```
          # class MyCommand < Marten::CLI::Command
          #   def setup
          #     on_argument(:arg, "The name of the argument") do |value|
          #       @arg_var = value
          #     end
          #   end
          # end
          # ```
          def on_argument(name : String | Symbol, description : String, &block : String ->)
            name = name.to_s
            append_argument(name, description)
            @argument_handlers << ArgumentHandler.new(name, block)
          end

          # Allows to configure a specific command option.
          #
          # This method will configure a command option (eg. `--option`). It expects a flag name, a description, and it
          # yields a block to let the command properly assign the option value to the command object:
          #
          # ```
          # class MyCommand < Marten::CLI::Command
          #   def setup
          #     on_option(:option, "The name of the option") do
          #       @option_var = true
          #     end
          #   end
          # end
          # ```
          #
          # Note that the `--` must not be included in the option name.
          def on_option(flag : String | Symbol, description : String, &block : String ->)
            parser.on("--#{flag}", description, &block)
          end

          # Allows to configure a specific command option.
          #
          # This method will configure a command option (eg. `--option`). It expects a flag name, a short flag name, a
          # description, and it yields a block to let the command properly assign the option value to the command
          # object:
          #
          # ```
          # class MyCommand < Marten::CLI::Command
          #   def setup
          #     on_option("o", "option", "The name of the option") do
          #       @option_var = true
          #     end
          #   end
          # end
          # ```
          #
          # Note that the `--` must not be included in the option name.
          def on_option(
            short_flag : String | Symbol,
            long_flag : String | Symbol,
            description : String,
            &block : String ->
          )
            parser.on("-#{short_flag}", "--#{long_flag}", description, &block)
          end

          # Allows to configure a specific command option with an associated argument.
          #
          # This method will configure a command option (eg. `--option`) and an associated argument. It expects a flag
          # name, an argument name, a description, and it yields a block to let the command properly assign the option
          # value to the command object:
          #
          # ```
          # class MyCommand < Marten::CLI::Command
          #   def setup
          #     on_option_with_arg(:option, :arg, "The name of the option") do |arg|
          #       @arg = arg
          #     end
          #   end
          # end
          # ```
          #
          # Note that the `--` must not be included in the option name.
          def on_option_with_arg(
            flag : String | Symbol,
            arg : String | Symbol,
            description : String,
            &block : String ->
          )
            parser.on("--#{flag}=#{arg.to_s.upcase}", description, &block)
          end

          # Allows to configure a specific command option with an associated argument.
          #
          # This method will configure a command option (eg. `--option`) and an associated argument. It expects a flag
          # name, a short flag name, an argument name, a description, and it yields a block to let the command properly
          # assign the option value to the command object:
          #
          # ```
          # class MyCommand < Marten::CLI::Command
          #   def setup
          #     on_option_with_arg("o", "option", "arg", "The name of the option") do |arg|
          #       @arg = arg
          #     end
          #   end
          # end
          # ```
          #
          # Note that the `--` must not be included in the option name.
          def on_option_with_arg(
            short_flag : String | Symbol,
            long_flag : String | Symbol,
            arg : String | Symbol,
            description : String,
            &block : String ->
          )
            parser.on("-#{short_flag} #{arg.to_s.upcase}", "--#{long_flag}=#{arg.to_s.upcase}", description, &block)
          end

          # Allows to print a message to the output file descriptor.
          #
          # This method will print a textual value to the output file descriptor, and it allows to optionally specify
          # the ending character (which defaults to a newline):
          #
          # ```
          # print("This is a message")
          # print("This is a message without newline", ending = "")
          # ```
          def print(msg, ending = "\n")
            msg = msg.to_s
            msg += ending if ending && !msg.ends_with?(ending)
            @stdout.print(msg)
          end

          # Allows to print a message to the error file descriptor.
          def print_error(msg)
            @stderr.puts(msg.colorize.toggle(color).bright)
          end

          # Allows to print a message to the error file descriptor and to exit the execution of the command.
          #
          # The code used to exit the execution of the command can be specified using the `exit_code` argument (defaults
          # to `1`).
          def print_error_and_exit(msg, exit_code = 1)
            @stderr.print(style("Error: ", fore: :red, mode: :bold))
            print_error(msg)
            exit(exit_code)
          end

          # Runs the command.
          #
          # This method should be overridden by subclasses in order to implement the execution logic of the considered
          # command.
          def run
          end

          # Setups the command.
          #
          # This method should be overridden by subclasses in order to configure the command arguments and options
          # through the use of the `#on_argument` and `#on_option` methods.
          def setup
          end

          # Allows to apply a style to a specific text value.
          #
          # This method can be used to apply `fore`, `back`, and `mode` styles to a specific text values. This method is
          # likely to be used in conjunction with the `#print` method when outputting messages:
          #
          # ```
          # print(style("This is a text", fore: :light_blue, back: :green, mode: :bold))
          # ```
          def style(msg, fore = nil, back = nil, mode = nil)
            output = msg.colorize.toggle(color)
            output.fore(fore) unless fore.nil?
            output.back(back) unless back.nil?
            output.mode(Colorize::Mode.parse(mode.to_s)) unless mode.nil?
            output.to_s
          end

          private getter arguments
          private getter argument_handlers
          private getter color
          private getter options

          private def append_argument(name, description)
            if name.size >= 33
              @arguments << "    #{name}\n#{" " * 37}#{description}"
            else
              @arguments << "    #{name}#{" " * (33 - name.size)}#{description}"
            end
          end

          private def banner_parts
            banner_parts = [] of String

            banner_parts << "Usage: #{@main_command_name} #{self.class.command_name} [options]"
            unless arguments.empty?
              banner_parts << " #{argument_handlers.join(" ") { |h| "[#{h.name}]" }}"
            end

            banner_parts << "\n\n"

            banner_parts << "#{self.class.help}\n\n" unless self.class.help.empty?

            unless arguments.empty?
              banner_parts << "Arguments:\n"
              banner_parts << arguments.join("\n")
              banner_parts << "\n\n"
            end

            banner_parts << "Options:"
          end

          private def parser
            @parser.not_nil!
          end

          private def show_error_trace?
            @show_error_trace
          end
        end
      end
    end
  end
end
