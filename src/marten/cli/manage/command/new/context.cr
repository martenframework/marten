module Marten
  module CLI
    class Manage
      module Command
        class New < Base
          class Context
            property database : String
            property edge : Bool? = false
            property name : String
            property targets : Array(String)

            TARGET_AUTH    = "auth"
            TARGET_GENERAL = "general"

            def initialize(
              @name = "example",
              @database = "sqlite3",
              @targets = [TARGET_GENERAL],
              @edge = false
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
