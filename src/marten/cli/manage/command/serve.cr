module Marten
  module CLI
    class Manage
      module Command
        class Serve < Base
          @host : String?
          @port : Int32?

          command_aliases :s
          help "Start a development server that is automatically recompiled when source files change."

          def setup
            on_option_with_arg(
              :b,
              :bind,
              arg: "host",
              description: "Custom host to bind"
            ) do |v|
              @host = v
            end

            on_option_with_arg(
              :p,
              :port,
              arg: "port",
              description: "Custom port to listen for connections"
            ) do |v|
              @port = v.to_i
            end
          end

          def run
            loop do
              scan_server_files
              sleep 0.2
            end
          end

          private FILES_TO_WATCH = [
            "./src/**/*.cr",
            "./src/**/*.ecr",
            "./config/**/*.cr",
            "./config/**/*.ecr",
            "./shard.lock",
          ]

          private SERVER_BUILD_PATH = "tmp/manage"

          private getter host
          private getter port
          private getter server_build_success : Bool = false
          private getter server_process : Process? = nil

          private setter server_build_success
          private setter server_process

          private def build_server
            FileUtils.mkdir_p("tmp")

            command = String.build do |s|
              s << "crystal build src/server.cr -o #{SERVER_BUILD_PATH}"
              s << " --error-trace" if show_error_trace?
            end

            stdout.print("⧖ Compiling...")

            tmp_stdout = IO::Memory.new
            tmp_stderr = IO::Memory.new

            build_status = Spinner.start("Compiling...", stdout) do
              Process.run(command, shell: true, input: STDIN, output: tmp_stdout, error: tmp_stderr)
            end

            self.server_build_success = build_status.success?

            # Prints the result of the server binary compilation.
            stdout.print(tmp_stdout.to_s)
            stderr.print(tmp_stderr.to_s)
          end

          private def file_modification_timestamps
            @file_modification_timestamps ||= {} of String => String
          end

          private def scan_server_files
            file_changed = false

            Dir.glob(FILES_TO_WATCH) do |filepath|
              modification_timestamp = File.info(filepath).modification_time.to_s("%Y%m%d%H%M%S")

              if !file_modification_timestamps[filepath]?
                file_modification_timestamps[filepath] = modification_timestamp
                file_changed = server_process.nil? || server_process.not_nil!.terminated?
              elsif file_modification_timestamps[filepath] != modification_timestamp
                file_modification_timestamps[filepath] = modification_timestamp
                file_changed = true
              end
            end

            if file_changed
              stop_server_process
              build_server
              start_server_process if self.server_build_success
            end
          end

          private def start_server_process
            args = [
              host ? "-b #{host}" : nil,
              port ? "-p #{port}" : nil,
            ].compact

            self.server_process = Process.new(
              SERVER_BUILD_PATH,
              args: args,
              shell: false,
              output: stdout,
              error: stderr
            )
          end

          private def stop_server_process
            server_process.not_nil!.signal(:term) unless server_process.nil? || server_process.not_nil!.terminated?
          end
        end
      end
    end
  end
end
