module Marten
  module Conf
    class GlobalSettings
      # Allows to configure templates-related settings.
      class Templates
        @app_dirs : Bool = true
        @dirs : Array(String) = [] of String

        # Returns a boolean indicating whether templates should be looked for inside installed applications.
        getter app_dirs

        # Returns an array of directories where templates should be looked for.
        #
        # The order of these directories is important as it defines the order in which templates are searched for.
        getter dirs

        # Allows to set whether templates should be looked for inside installed applications.
        setter app_dirs

        # Allows to set the directories where templates should be looked for.
        setter dirs
      end
    end
  end
end
