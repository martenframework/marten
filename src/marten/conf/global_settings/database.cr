module Marten
  module Conf
    class GlobalSettings
      # Defines the configuration of a specific database connection.
      class Database
        @backend : String | Symbol | Nil
        @name : Path | String | Symbol | Nil

        getter id
        getter backend
        getter name

        setter backend
        setter name

        def initialize(@id : String)
        end
      end
    end
  end
end
