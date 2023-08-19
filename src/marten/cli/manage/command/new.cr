require "./new/**"

module Marten
  module CLI
    class Manage
      module Command
        class New < Base
          help "Initialize a new Marten project or application repository."

          @dir : String?
          @interactive_mode : Bool = false
          @name : String?
          @type : String?
          @with_auth : Bool = false
          @database : String = "sqlite3"

          def setup
            on_argument(:type, "Type of structure to initialize: 'project' or 'app'") { |v| @type = v }
            on_argument(:name, "Name of the project or app to initialize") { |v| @name = v }
            on_option_with_arg(:d, :dir, arg: "dir", description: "Optional destination directory") { |v| @dir = v }
            on_option(:"with-auth", "Adds authentication to newly created projects") { @with_auth = true }
            on_option_with_arg(
              :database,
              arg: "db",
              description: "Configure default database (options: mysql/postgresql/sqlite3)") do |db|
              @database = db
            end
          end

          def run
            setup_interactive_mode

            print_welcome_message if interactive_mode? && (type.nil? || project? || app?)
            ask_for_structure_type if type.nil? || type.not_nil!.empty?

            if !project? && !app?
              print_error(invalid_structure_type_error_message)
              return
            end

            ask_for_project_or_app_name if name.nil? || name.not_nil!.empty?
            if !name_valid?
              print_error(invalid_project_or_app_name_error_message)
              return
            end

            ask_for_database if interactive_mode? && !app?
            if !database_valid?
              print_error(invalid_database_engine_error_message)
              return
            end

            ask_for_auth_app_addition if interactive_mode? && project? && !with_auth?

            if app? && with_auth?
              print_error("--with-auth can only be used when creating new projects")
            end

            context = Context.new
            context.name = name.not_nil!
            context.targets << Context::TARGET_AUTH if with_auth?
            context.database = database

            create_files(
              project? ? Templates.project_files(context) : Templates.app_files(context),
              Path.new((@dir.nil? || @dir.not_nil!.empty?) ? name.not_nil! : @dir.not_nil!).expand
            )
          end

          private NAME_RE             = /^[-a-zA-Z0-9_]+$/
          private SUPPORTED_DATABASES = {"sqlite3", "postgresql", "mysql"}
          private TYPE_APP            = "app"
          private TYPE_PROJECT        = "project"

          private getter database
          private getter dir
          private getter name
          private getter type

          private getter? interactive_mode
          private getter? with_auth

          private def app? : Bool
            type == TYPE_APP
          end

          private def ask_for_auth_app_addition(show_explanation : Bool = true) : Nil
            if show_explanation
              print_explanation(
                "Marten allows the generation of new projects with a built-in 'auth' application that efficiently " \
                "handles basic user management requirements through email/password authentication."
              )
            end

            print(style("\nInclude authentication [yes/no]?", mode: :bold), ending: " ")

            unless %w(y yes n no).includes?(answer = stdin.gets.to_s.downcase)
              ask_for_auth_app_addition(show_explanation: false)
            end

            @with_auth = %w(y yes).includes?(answer)
          end

          private def ask_for_database(show_explanation : Bool = true) : Nil
            if show_explanation
              print_explanation(
                "Which database to use? " \
                "Select from sqlite3, mysql and postgresql (default: sqlite3)"
              )
            end

            print(style("\nDatabase:", mode: :bold), ending: " ")
            @database = stdin.gets.to_s.downcase.strip
            @database = "sqlite3" if @database.empty?

            if !database_valid?
              print(invalid_database_engine_error_message)
              ask_for_database(show_explanation: false)
            end
          end

          private def ask_for_project_or_app_name(show_explanation : Bool = true) : Nil
            if show_explanation
              print_explanation(
                "How to name your #{project? ? "project" : "app"}? " \
                "#{project? ? "Project" : "App"} names can only contain letters, numbers, underscores, and dashes."
              )
            end

            print(style("\n#{project? ? "Project" : "App"} name:", mode: :bold), ending: " ")
            @name = stdin.gets.to_s.downcase.strip

            if !name_valid?
              print(invalid_project_or_app_name_error_message)
              ask_for_project_or_app_name(show_explanation: false)
            end
          end

          private def ask_for_structure_type(show_explanation : Bool = true) : Nil
            if show_explanation
              print_explanation(
                "Which type of structure should be created? A 'project' corresponds to an entire webapp. An 'app' " \
                "corresponds to a reusable component that can be shared across multiple projects."
              )
            end

            print(style("\nStructure type ('project or 'app'):", mode: :bold), ending: " ")
            @type = stdin.gets.to_s.downcase

            if !project? && !app?
              print(invalid_structure_type_error_message)
              ask_for_structure_type(show_explanation: false)
            end
          end

          private def create_files(files, expanded_dir)
            print("") if interactive_mode?

            files.sort_by { |f| f[0] }.each do |file_path, file_content|
              print("› Creating #{style(file_path, mode: :dim)}...", ending: "")

              full_path = expanded_dir.join(file_path)
              Dir.mkdir_p(full_path.dirname)
              File.write(full_path, file_content)

              print(style(" DONE", fore: :light_green, mode: :bold))
            end
          end

          private def database_valid? : Bool
            SUPPORTED_DATABASES.includes? @database.downcase
          end

          private def invalid_database_engine_error_message : String
            "Invalid database. Supported databases are: mysql, postgresql, sqlite3."
          end

          private def invalid_project_or_app_name_error_message : String
            "#{project? ? "Project" : "App"} name can only contain letters, numbers, underscores, and dashes."
          end

          private def invalid_structure_type_error_message : String
            "Unrecognized structure type, you must use 'project or 'app'."
          end

          private def name_valid? : Bool
            !@name.nil? && !@name.not_nil!.empty? && NAME_RE.matches?(@name.to_s)
          end

          private def print_explanation(explanation : String) : Nil
            print(style("\n#{explanation}", mode: :dim), ending: "")
          end

          private def print_welcome_message : Nil
            welcome_message = " Welcome to Marten #{Marten::VERSION}! "
            print(style(" " * welcome_message.size, mode: :bold, fore: :light_red, back: :white))
            print(style(welcome_message, mode: :bold, fore: :light_red, back: :white))
            print(style(" " * welcome_message.size, mode: :bold, fore: :light_red, back: :white))
          end

          private def project? : Bool
            type == TYPE_PROJECT
          end

          private def setup_interactive_mode : Bool
            @interactive_mode = (
              type.nil? ||
              type.not_nil!.empty? ||
              (!type.nil? && (name.nil? || name.not_nil!.empty?))
            )
          end
        end
      end
    end
  end
end
