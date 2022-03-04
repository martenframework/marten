module Marten
  module Apps
    # Main application config class.
    #
    # Marten automatically defines a "main" application config that corresponds to the standard `src/` folder. Models,
    # migrations, assets, or locales that live in this folder will be automatically known by Marten (like if they were
    # part of any other installed application). The rationale behind this is that this allows simple projects to be
    # started without requiring the definition of applications upfront, which is ideal for simple projects or proofs of
    # concept.
    class MainConfig < Config
      RESERVED_LABEL = "main"

      @@label = RESERVED_LABEL

      # :nodoc:
      def self._marten_app_location
        {{ run("./main_config/fetch_src_path.cr") }}
      end
    end
  end
end
