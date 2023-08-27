module Marten
  module CLI
    class Manage
      module Command
        class Gen < Base
          command_aliases :g
          help "Generate various structures, abstractions, and values within an existing project."

          @@generator_registry = [] of Generator.class

          @generator : Generator?
          @generator_name : String?
          @generators_per_name : Hash(String, Generator.class)?

          # :nodoc:
          class_getter generator_registry

          # :nodoc:
          def self.register_generator(generator_klass : Generator.class)
            @@generator_registry << generator_klass
          end

          def setup
            on_argument(GENERATOR_ARGUMENT_NAME, "Name of the generator to use") { |v| @generator_name = v }

            generator_name = options.first?
            if !generator_name.nil? && !(generator_klass = generators_per_name[generator_name]?).nil?
              @generator = generator_klass.new(self)
              @generator.try(&.setup)
            elsif !generator_name.nil?
              # Silence possible unknown arguments and options since unknown arguments/options identified in this
              # command might result from a typo in the generator name.
              on_invalid_option { }
              on_unknown_argument { }
            end
          end

          def run
            if generator_name.nil?
              show_usage
              return
            end

            if generator.nil?
              print_error_and_exit("Unknown generator '#{generator_name}'")
            end

            generator!.run
          end

          private GENERATOR_ARGUMENT_NAME = "generator"

          private getter generator
          private getter generator_name

          private def banner_parts
            banner_parts = [] of String

            if generator.nil?
              effective_command_name = "gen"
              effective_help = self.class.help
              effective_argument_handlers = argument_handlers
              effective_argument_descriptions = argument_descriptions
            else
              effective_command_name = "gen #{generator!.class.generator_name}"
              effective_help = generator!.class.help
              effective_argument_handlers = argument_handlers.reject { |h| h.name == GENERATOR_ARGUMENT_NAME }
              effective_argument_descriptions = argument_descriptions.reject { |k, _| k == GENERATOR_ARGUMENT_NAME }
            end

            banner_parts << "Usage: #{@main_command_name} #{effective_command_name} [options]"
            unless effective_argument_handlers.empty?
              arguments_line = " #{effective_argument_handlers.join(" ") { |h| "[#{h.name}]" }}"
              if !unknown_args_proc.nil?
                arguments_line += " [arguments]"
              end

              banner_parts << arguments_line
            end

            banner_parts << "\n\n"

            banner_parts << "#{effective_help}\n\n" unless effective_help.empty?

            unless effective_argument_descriptions.empty?
              banner_parts << "Arguments:\n"
              banner_parts << effective_argument_descriptions
                .map { |n, d| format_argument_name_and_description(n, d) }
                .join("\n")
              banner_parts << "\n\n"
            end

            banner_parts << "Options:"
          end

          private def generator!
            generator.not_nil!
          end

          private def generators_per_name
            @generators_per_name ||= begin
              mapping = Hash(String, Generator.class).new

              @@generator_registry.each do |generator|
                mapping[generator.generator_name] = generator
              end

              mapping
            end
          end

          private def show_available_generators
            usage = ["\nAvailable generators are listed below.\n\n"]

            per_app_generators = generators_per_name.values.group_by do |generator|
              if generator._marten_app_location.starts_with?(Marten._marten_app_location)
                "marten"
              else
                generator.app_config.label
              end
            end

            per_app_generators.each do |app_label, generators|
              usage << "[#{app_label}]\n\n"
              generators.uniq.each do |generator|
                usage << "  › #{generator.generator_name}"
                usage << "\n"
              end
              usage << "\n"
            end

            usage << "Run a generator followed by --help to see generator specific information, ex:\n"
            usage << "marten gen [generator] --help"

            print(usage.join(""))
          end

          private def show_usage
            if generator.nil?
              super

              show_available_generators
            else
              super
            end
          end
        end
      end
    end
  end
end
