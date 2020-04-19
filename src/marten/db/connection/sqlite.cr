module Marten
  module DB
    module Connection
      class SQLite < Base
        def scheme : String
          "sqlite3"
        end
      end
    end
  end
end
