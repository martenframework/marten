module Marten
  module CLI
    class Manage
      module Command
        class ClearSessions < Base
          command_name :clearsessions
          help "Clears all expired sessions."
          getter no_input

          @no_input : Bool = false

          def setup
            on_option("no-input", "Do not show prompts to the user") { @no_input = true }
          end

          def run
            unless no_input
              print("All expired sessions will be removed.")
              print("These sessions can't be restored.")
              print("Do you want to continue [yes/no]?", ending: " ")
              unless %w(y yes).includes?(stdin.gets.to_s.downcase)
                print("Cancelling...")
                return
              end
            end

            print(style("Clearing expired sessions", fore: :light_blue, mode: :bold), ending: "\n")

            session_store_klass = HTTP::Session::Store.get(Marten.settings.sessions.store)
            session_store_klass.new(nil).clear_expired_entries
          end
        end
      end
    end
  end
end
