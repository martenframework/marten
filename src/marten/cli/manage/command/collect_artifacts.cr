module Marten
  module CLI
    class Manage
      module Command
        class CollectArtifacts < Base
          command_name :collectartifacts
          help "Collect runtime artifacts required by compiled applications."

          @app_label : String?
          @dest_path : String = "artifacts"
          @no_input : Bool = false

          def setup
            on_option_with_arg(
              "dest-path",
              arg: "Path",
              description: %(Specify where artifacts should be collected (defaults to "artifacts").)
            ) do |v|
              @dest_path = v
            end

            on_option("no-input", "Do not show prompts to the user") { @no_input = true }

            on_option_with_arg(
              "app",
              arg: "Label",
              description: "Collect artifacts for a specific application only."
            ) do |v|
              @app_label = v
            end
          end

          def run
            artifacts = discover_artifacts

            unless no_input?
              print("Runtime artifacts will be collected into '#{dest_path}'.")
              print("Any existing files will be overwritten.")
              print("Do you want to continue [yes/no]?", ending: " ")
              unless %w(y yes).includes?(stdin.gets.to_s.downcase)
                print("Cancelling...")
                return
              end
            end

            print(style("Collecting runtime artifacts:", fore: :light_blue, mode: :bold), ending: "\n")
            collect(artifacts)
          end

          private record Artifact, source_path : Path, relative_path : Path
          private record Source, dir : Path, dest_prefix : Path

          private getter app_label
          private getter dest_path

          private def add_app_sources(sources, app_config)
            app_config.artifact_dirs.each do |dir|
              sources << build_source(dir) if Dir.exists?(dir)
            end
          end

          private def app_config(label)
            Marten.apps.get(label)
          rescue e : Apps::Errors::AppNotFound
            print_error_and_exit(e.message)
          end

          private def artifact_sources
            sources = [] of Source

            if label = app_label
              add_app_sources(sources, app_config(label))
            else
              # Mirrors the built-in locales lookup performed by Marten.setup_i18n.
              marten_locales_dir = Path[Marten._marten_app_location].join("marten", "locales")
              sources << build_source(marten_locales_dir) if Dir.exists?(marten_locales_dir)

              # Mirrors the Marten.root.join("config/locales") lookup performed by Marten.setup_i18n: project
              # locales are anchored at the destination root so that the collected tree matches the runtime
              # lookup when the root_path setting points to the destination directory.
              project_locales_dir = Path[Marten.apps.main.class._marten_app_location]
                .join("..", "config", "locales")
                .expand
              if Dir.exists?(project_locales_dir)
                sources << Source.new(project_locales_dir, Path["config"].join("locales"))
              end

              Marten.apps.app_configs.each do |app_config|
                add_app_sources(sources, app_config)
              end
            end

            sources.uniq(&.dir.expand)
          end

          private def build_source(dir)
            relative_dir = dir.relative_to(compilation_root_path)

            if relative_dir.to_s == ".." || relative_dir.to_s.starts_with?("../")
              print_error_and_exit(
                "Cannot collect artifacts from '#{dir}' because it is outside the compilation root " \
                "'#{compilation_root_path}'"
              )
            end

            Source.new(dir, relative_dir)
          end

          private def collect(artifacts)
            collected_count = 0

            artifacts.each do |artifact|
              copy_artifact_file(artifact)
              collected_count += 1
            end

            if collected_count == 0
              print("No artifacts to collect...")
            end
          end

          private def compilation_root_path
            Path[Marten::Apps::Config.compilation_root_path]
          end

          private def copy_artifact_file(artifact)
            destination_path = Path[dest_path].join(artifact.relative_path)

            print("  › Copying #{style(artifact.relative_path.to_s, mode: :dim)}...", ending: "")

            begin
              FileUtils.mkdir_p(destination_path.dirname)
              FileUtils.cp(artifact.source_path, destination_path)
            rescue e : IO::Error
              print(style(" ERROR", fore: :red, mode: :bold))
              print_error_and_exit("Could not copy '#{artifact.source_path}': #{e.message}")
            end

            print(style(" DONE", fore: :light_green, mode: :bold))
          end

          private def discover_artifacts
            artifacts = artifact_sources.flat_map do |source|
              Dir.glob(
                source.dir.join("**", "*").to_s,
                match: File::MatchOptions.glob_default | File::MatchOptions::DotFiles,
                follow_symlinks: true
              )
                .reject { |path| File.directory?(path) }
                .map { |path| Artifact.new(Path[path], source.dest_prefix.join(Path[path].relative_to(source.dir))) }
            end

            artifacts.sort_by!(&.relative_path.to_s)
          end

          private def no_input?
            @no_input
          end
        end
      end
    end
  end
end
