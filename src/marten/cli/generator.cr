module Marten
  module CLI
    # Abstract generator.
    #
    # Generators are classes that operate in the context of the `gen` management command. They can be leveraged to
    # generate new abstractions, structures, and files within an existing application.
    abstract class Generator
      include Apps::Association

      @@app_config : Marten::Apps::Config?
      @@footer_description : String? = nil
      @@generator_name = ""
      @@help : String = ""

      @warnings = [] of String

      # Returns the footer description of the generator.
      class_getter footer_description

      # Returns the help description of the generator.
      class_getter help

      # Returns the command instance that is used to invoke the generator.
      getter command

      # Returns an array of warning messages that should be printed at the end of the generator execution.
      getter warnings

      # Allows to set the warning messages that should be printed at the end of the generator execution.
      setter warnings

      # Allows to define a footer description that will be displayed after the generator usage help.
      def self.footer_description(footer_description : String | Symbol)
        @@footer_description = footer_description.to_s
      end

      # Returns the name of the considered generator.
      def self.generator_name
        return @@generator_name unless @@generator_name.empty?
        @@generator_name = name.split("::").last.underscore
      end

      # Allows to set the name of the generator.
      #
      # The value set using this method will be used by users when they invoke the generator through the use of the
      # `marten gen` management command.
      def self.generator_name(name : String | Symbol)
        @@generator_name = name.to_s
      end

      # Allows to set the help description of the generator.
      def self.help(help : String)
        @@help = help
      end

      protected def self.app_config
        @@app_config ||= Marten.apps.get_containing(self)
      end

      def initialize(@command : Manage::Command::Gen)
      end

      # Creates the specified files under the passed application config.
      #
      # `files` must be an array of tuples where the first element is the path of the file to create and the second
      # element is the content of the file.
      def create_app_files(app_config : Apps::Config, files : Array(Tuple(String, String)))
        expanded_dir = Path.new(app_config.class._marten_app_location).expand

        files.sort_by { |f| f[0] }.each do |file_path, file_content|
          full_path = expanded_dir.join(file_path)

          command.print(
            "› Creating #{command.style(full_path.relative_to(FileUtils.pwd), fore: :cyan, mode: :bold)}...", ending: ""
          )

          Dir.mkdir_p(full_path.dirname)
          File.write(full_path, file_content)

          command.print(command.style(" DONE", fore: :light_green, mode: :bold))
        end
      end

      # Creates the specified files under the project's spec folder.
      #
      # `files` must be an array of tuples where the first element is the path of the file to create and the second
      # element is the content of the file.
      def create_spec_files(files : Array(Tuple(String, String)))
        expanded_dir = Path.new(Marten.apps.main.class._marten_app_location).expand.join("../spec")

        files.sort_by { |f| f[0] }.each do |file_path, file_content|
          full_path = expanded_dir.join(file_path)

          command.print(
            "› Creating #{command.style(full_path.relative_to(FileUtils.pwd), fore: :cyan, mode: :bold)}...", ending: ""
          )

          Dir.mkdir_p(full_path.dirname)
          File.write(full_path, file_content)

          command.print(command.style(" DONE", fore: :light_green, mode: :bold))
        end
      end

      abstract def run : Nil

      # Prints the warning messages that have been collected during the generator execution.
      def print_warnings
        if !warnings.empty?
          command.print("\n")
          command.print(command.style("Warnings:", fore: :yellow, mode: :bold))
          warnings.each do |warning|
            command.print("  ○ #{warning}")
          end
        end
      end

      def setup
      end

      macro inherited
        Marten::CLI::Manage::Command::Gen.register_generator({{ @type }})
      end
    end
  end
end
