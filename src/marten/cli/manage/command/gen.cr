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

          def show_usage
            if !(g = generator).nil?
              super

              if !g.class.footer_description.nil?
                print("\n")
                print(g.class.footer_description.to_s)
              end
            else
              super
              show_available_generators
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
            generator!.print_warnings
          end

          private GENERATOR_ARGUMENT_NAME = "generator"

          private getter generator
          private getter generator_name

          private def banner_argument_descriptions
            if generator.nil?
              argument_descriptions
            else
              argument_descriptions.reject { |k, _| k == GENERATOR_ARGUMENT_NAME }
            end
          end

          private def banner_argument_handlers
            if generator.nil?
              argument_handlers
            else
              argument_handlers.reject { |h| h.name == GENERATOR_ARGUMENT_NAME }
            end
          end

          private def banner_command_name
            if generator.nil?
              self.class.command_name
            else
              "#{self.class.command_name} #{generator!.class.generator_name}"
            end
          end

          private def banner_help
            if generator.nil?
              self.class.help
            else
              generator!.class.help
            end
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
        end
      end
    end
  end
end
