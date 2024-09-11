module Marten
  module CLI
    class Manage
      module Command
        class Seed < Base
          @seed_path : String = "./seed.cr"

          help "Populate the database by running the seed file."

          def setup
            on_option_with_arg(
              :f,
              :file,
              arg: "path",
              description: "Specify a custom path to the seed file"
            ) do |v|
              @seed_path = v
            end
          end

          def run
            run_seed_file
          end

          private getter seed_path

          private def run_seed_file
            if File.exists?(seed_path)
              print "Running seed file at #{seed_path}"
              Process.run("crystal #{seed_path}", shell: true, output: stdout, error: stderr)
            else
              print "Seed file not found at #{seed_path}."
            end
          end
        end
      end
    end
  end
end
