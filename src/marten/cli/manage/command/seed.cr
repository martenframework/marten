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

          private SEED_SOURCE_CONTENT = ECR.render("#{__DIR__}/new/templates/app/src/app/seed.cr.ecr")

          private getter seed_path

          private def run_seed_file
            if File.exists?(seed_path)
              print "Running seed file at #{seed_path}"
              begin
                Process.run("crystal #{seed_path}", shell: true, output: stdout, error: stderr)
              rescue ex : Exception
                print "Error running seed file: #{ex.message}"
              end
            else
              print "Seed file not found at #{seed_path}. Generating default seed.cr..."
              write_seed_file
            end
          end

          private def write_seed_file
            unless File.exists?(seed_path)
              FileUtils.mkdir_p(Path[seed_path].dirname)
              File.write(seed_path, SEED_SOURCE_CONTENT)
              print "Default seed file generated at #{seed_path}."
            end
          end
        end
      end
    end
  end
end
