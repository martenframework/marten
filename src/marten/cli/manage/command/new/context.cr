module Marten
  module CLI
    class Manage
      module Command
        class New < Base
          class Context
            property name : String
            property targets : Array(String)
            property database : String

            TARGET_AUTH    = "auth"
            TARGET_GENERAL = "general"

            def initialize(
              @name = "example",
              @database = "sqlite3",
              @targets = [TARGET_GENERAL]
            )
            end

            def capitalized_name : String
              name.split("_").map(&.capitalize).join
            end

            def targets_auth?
              @targets.includes?(TARGET_AUTH)
            end
          end
        end
      end
    end
  end
end
