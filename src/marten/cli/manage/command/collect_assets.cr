module Marten
  module CLI
    class Manage
      module Command
        class CollectAssets < Base
          command_name :collectassets
          help "Collect all the assets and copy them in a unique storage."

          @no_input : Bool = false

          def setup
            on_option("no-input", "Do not show prompts to the user") { @no_input = true }
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
          end

          private def copy_asset_file(relative_path, absolute_path)
            File.open(absolute_path) do |io|
              print("  › Copying #{style(relative_path, mode: :dim)}...", ending: "")
              Marten.assets.storage.write(relative_path, io)
              print(style(" DONE", fore: :light_green, mode: :bold))
            end
          end

          private def no_input?
            @no_input
          end
        end
      end
    end
  end
end
