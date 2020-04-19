module Marten
  module Conf
    class GlobalSettings
      class Database
        @backend : String | Symbol | Nil
        @name : Symbol | String | Nil

        getter id
        getter backend
        getter name

        setter backend
        setter name

        def initialize(@id : String | Symbol)
        end
      end
    end
  end
end
