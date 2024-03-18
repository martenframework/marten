require "digest/sha256"

module Marten
  module CLI
    class Manage
      module Command
        class CollectAssets < Base
          command_name :collectassets
          help "Collect all the assets and copy them in a unique storage."

          @fingerprint : Bool = false
          @fingerprint_mapping = Hash(String, String).new
          @no_input : Bool = false
          @manifest_path : String = File.join Marten.apps.main.class._marten_app_location, "manifest.json"

          def setup
            on_option("fingerprint", "Add a fingerprint to the collected assets") { @fingerprint = true }
            on_option("no-input", "Do not show prompts to the user") { @no_input = true }
            on_option_with_arg(
              "manifest-path",
              arg: "Filepath",
              description: "Specify where the manifest file should be stored."
            ) do |v|
              @manifest_path = v
            end
          end

          def run
            unless no_input?
              print("Assets will be collected into the storage configured in your application settings.")
              print("Any existing files will be overwritten.")
              print("Do you want to continue [yes/no]?", ending: " ")
              unless %w(y yes).includes?(stdin.gets.to_s.downcase)
                print("Cancelling...")
                return
              end
            end

            Marten.setup_assets

            print(style("Collecting assets:", fore: :light_blue, mode: :bold), ending: "\n")
            collect
          end

          private def calculate_fingerprint(relative_path, io)
            last_dot_index = relative_path.rindex(".")
            old_path = relative_path
            fingerprint = nil

            if last_dot_index != -1
              sha = Digest::SHA256.new
              sha.update io
              io.rewind
              fingerprint = sha.hexfinal
              relative_path = relative_path[0...last_dot_index] + ".#{fingerprint}" + relative_path[last_dot_index..]
              @fingerprint_mapping[old_path] = relative_path
            end

            return relative_path, fingerprint
          end

          private def collect
            collected_count = 0

            Marten.assets.finders.each do |finder|
              finder.list.each do |relative_path, absolute_path|
                copy_asset_file(relative_path, absolute_path)
                collected_count += 1
              end
            end

            if collected_count == 0
              print("No assets to collect...")
            end

            if fingerprint? && collected_count > 0
              FileUtils.mkdir_p(Path[@manifest_path].dirname) # Ensure path exists

              print("  › Creating #{style(@manifest_path, mode: :dim)}...", ending: "")
              File.open(@manifest_path, "w") do |file|
                file.print @fingerprint_mapping.to_json
              end
              print(style(" DONE", fore: :light_green, mode: :bold))
            end
          end

          private def copy_asset_file(relative_path, absolute_path)
            File.open(absolute_path) do |io|
              original_relative_path = relative_path
              relative_path, fingerprint = calculate_fingerprint(relative_path, io) if fingerprint?

              print("  › Copying #{style(original_relative_path, mode: :dim)}", ending: "")
              print(style(" (#{fingerprint})", mode: :dim), ending: "") if fingerprint
              print("...", ending: "")

              Marten.assets.storage.write(relative_path.not_nil!, io)
              print(style(" DONE", fore: :light_green, mode: :bold))
            end
          end

          private def fingerprint?
            @fingerprint
          end

          private def no_input?
            @no_input
          end
        end
      end
    end
  end
end
