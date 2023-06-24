module Marten
  module CLI
    class Manage
      module Command
        class ClearSessions < Base
          command_name :clearsessions
          help "Clears all expired sessions."

          @no_prompt : Bool = false

          def setup
            on_option("-y", "Do not show prompts to the user") { @no_prompt = true }
          end

          def run
            unless no_prompt?
              print("All expired sessions will be removed.")
              print("These sessions can't be restored.")
              print("Do you want to continue [yes/no]?", ending: " ")
              unless %w(y yes).includes?(stdin.gets.to_s.downcase)
                print("Cancelling...")
                return
              end
            end

            print(style("Clearing expired sessions", fore: :light_blue, mode: :bold), ending: "\n")

            HTTP::Session::Store.registry.each_value do |session_store_klass|
              store = session_store_klass.new(nil)
              store.clear_expired_entries
            end
          end

          private def no_prompt?
            @no_prompt
          end
        end
      end
    end
  end
end
