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
      DEFAULT_LABEL = "main"

      @@label = DEFAULT_LABEL

      # :nodoc:
      def self._marten_app_location
        {{ run("./main_config/fetch_src_path.cr") }}
      end

      # :nodoc:
      def self.validate_label(label : String | Symbol)
        # The empty label is allowed for the main application only.
        return if label.empty?

        super
      end

      def label
        @@label
      end

      # Returns `true` in order to indicate that this is the main application.
      def main?
        true
      end
    end
  end
end
