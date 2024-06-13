module Marten
  module CLI
    class Manage
      module Command
        class Play < Base
          @host : String?
          @open : Bool = false
          @playground_process : Process?
          @port : Int32?

          # :nodoc:
          getter playground_process

          help "Start a Crystal playground server initialized for the current project."

          def setup
            on_option_with_arg(
              :b,
              :bind,
              arg: "host",
              description: "Bind the playground to the specified IP"
            ) do |v|
              @host = v
            end

            on_option_with_arg(
              :p,
              :port,
              arg: "port",
              description: "Run the playground on the specified port"
            ) do |v|
              @port = v.to_i
            end

            on_option(:"open", description: "Open the playground in the default browser automatically") do
              @open = true
            end
          end

          def run
            write_playground_source
            @playground_process = Process.new(play_command, shell: true, output: stdout, error: stderr)
            Process.run(open_command, shell: true) if open?
            @playground_process.try(&.wait)
          end

          private PLAYGROUND_SOURCE_CONTENT = <<-CRYSTAL
          require "./src/project"

          # Setup the project.
          Marten.setup

          # Write your code here.
          CRYSTAL

          private PLAYGROUND_SOURCE_PATH = "tmp/project_playground.cr"

          private getter host
          private getter port

          private getter? open

          private def open_command
            # Identify which 'open' command to use based on the OS based on flags
            url = "http://#{host || "localhost"}:#{port || 8080}"

            open_command = ""
            {% if flag?(:linux) %}
              open_command = "xdg-open #{url}" # Linux
            {% elsif flag?(:win32) || flag?(:win64) %}
              open_command = "start #{url}" # Windows
            {% else %}
              open_command = "open #{url}" # macOS
            {% end %}
          end

          private def play_command
            command = String.build do |s|
              s << "crystal play"
              s << " --binding #{host}" if host
              s << " --port #{port}" if port
              s << " #{PLAYGROUND_SOURCE_PATH}"
            end
          end

          private def write_playground_source
            FileUtils.mkdir_p(Path[PLAYGROUND_SOURCE_PATH].dirname)
            File.write(PLAYGROUND_SOURCE_PATH, PLAYGROUND_SOURCE_CONTENT)
          end
        end
      end
    end
  end
end
