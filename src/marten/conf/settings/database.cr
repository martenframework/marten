module Marten
  module Conf
    class Settings
      class Database
        property backend : Symbol | Nil = nil
        property name : Symbol | String | Nil = nil
      end
    end
  end
end
