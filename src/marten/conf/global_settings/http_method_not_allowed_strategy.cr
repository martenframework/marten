module Marten
  module Conf
    class GlobalSettings
      enum UnsupportedHttpMethodStrategy
        DENY # Method Not Allowed (405)
        HIDE # Not Found (404)
      end
    end
  end
end
