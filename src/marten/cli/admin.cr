module Marten
  module CLI
    # The admin CLI.
    #
    # The admin CLI is a wrapper around the management CLI: when used inside a Marten project, it allows to conveniently
    # compile the management CLI in order to issue commands in order to interact with the database and the installed
    # applications. When used outside of a Marten project, the admin CLI provides a simple way to initialize a new app
    # or project through the use of the `new` sub-command.
    class Admin
      def initialize(@options : Array(String), @stdout : IO = STDOUT, @stderr : IO = STDERR)
      end

      def run
        if inside_project?
          handle_inside_of_project_invocation
        else
          handle_outside_of_project_invocation
        end
      end

      private MANAGE_BUILD_PATH = "tmp/manage"

      private getter options
      private getter stdout
      private getter stderr

      private def build_and_run_manage_command
        build_status = build_manage_binary

        if build_status.success?
          exit Process.run(
            "#{MANAGE_BUILD_PATH} #{options.join(' ')}",
            shell: true,
            input: STDIN,
            output: STDOUT,
            error: STDERR
          ).exit_code
        else
          exit build_status.exit_code
        end
      end

      private def build_manage_binary
        FileUtils.mkdir_p("tmp")

        command = String.build do |s|
          s << "crystal build #{manage_filepath} -o #{MANAGE_BUILD_PATH}"
          s << " --error-trace" if options.includes?("--error-trace")
        end

        tmp_stdout = IO::Memory.new
        tmp_stderr = IO::Memory.new

        build_status = Spinner.start("Compiling...", stdout) do
          Process.run(command, shell: true, input: STDIN, output: tmp_stdout, error: tmp_stderr)
        end

        # Prints the result of the manage binary compilation.
        stdout.print(tmp_stdout.to_s)
        stderr.print(tmp_stderr.to_s)

        build_status
      end

      private def handle_inside_of_project_invocation
        command = options.first?.to_s

        if command_invoked?(command, Manage::Command::New)
          Manage::Command::New.new(options: options[1..], stdout: stdout, stderr: stderr).handle
        elsif command_invoked?(command, Manage::Command::Serve)
          Manage::Command::Serve.new(options: options[1..], stdout: stdout, stderr: stderr).handle
        else
          build_and_run_manage_command
        end
      end

      private def handle_outside_of_project_invocation
        command = options.first?

        if command == "version" || command == "--version" || command == "-v"
          show_version
          exit
        end

        if !command || command == "--help" || command == "-h" || command != "new"
          show_new_command_usage
          exit
        end

        options.shift

        Manage::Command::New.new(options: options, stdout: stdout, stderr: stderr).handle
      end

      private def inside_project?
        File.file?(manage_filepath)
      end

      private def manage_filepath
        ENV.fetch("MARTEN_MANAGE_FILE", "./manage.cr")
      end

      private def command_invoked?(name : String, command_klass : Manage::Command::Base.class) : Bool
        name == command_klass.command_name || command_klass.command_aliases.includes?(name)
      end

      private def show_new_command_usage
        Manage::Command::New.new(options: ["--help"], stdout: stdout, stderr: stderr).handle
      end

      private def show_version
        Manage::Command::Version.new(options: [] of String, stdout: stdout, stderr: stderr).handle
      end
    end
  end
end
