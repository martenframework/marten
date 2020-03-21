module Marten
  module Conf
    class GlobalSettings
      class Database
        property backend : Symbol | Nil = nil
        property name : Symbol | String | Nil = nil
      end
    end
  end
end
