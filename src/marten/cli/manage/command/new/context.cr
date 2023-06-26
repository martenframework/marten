module Marten
  module CLI
    class Manage
      module Command
        class New < Base
          class Context
            property dir : String
            property name : String
            property targets : Array(String)
            property database : String

            TARGET_AUTH    = "auth"
            TARGET_GENERAL = "general"

            def initialize(
              @dir = "example",
              @name = "example",
              @database = "sqlite3",
              @targets = [TARGET_GENERAL]
            )
            end

            def expanded_dir
              Path.new(dir).expand
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
