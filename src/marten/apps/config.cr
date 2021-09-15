module Marten
  module Apps
    # Base application config class.
    #
    # This class can be subclassed on a per-application basis in order to configure the considered application. Things
    # like the application label can be configured this way. Moreover, app config classes are also used in order to
    # retrieve various abstractions associated with applications (such as models for example).
    abstract class Config
      include Association

      @@label = "app"

      getter models

      delegate label, to: self.class

      def self.label(label : String | Symbol)
        unless LABEL_RE.match(label.to_s)
          raise Errors::InvalidAppConfig.new("A label can only contain lowercase letters and underscores")
        end
        @@label = label.to_s
      end

      # Returns the label of the application config.
      def self.label : String
        @@label
      end

      def initialize
        @models = [] of DB::Model.class
      end

      # Returns true if the other app config corresponds to the current app config.
      def ==(other : self)
        super || (label == other.label && models == other.models)
      end

      # Returns the assets finder of the application.
      #
      # If the application doesn't have a dedicated assets directory, `nil` is returned.
      def assets_finder
        assets_dir = Path[self.class._marten_app_location].join(ASSETS_DIR)
        return unless Dir.exists?(assets_dir)
        Asset::Finder::FileSystem.new(assets_dir.to_s)
      end

      # Returns the migrations path for the application.
      def migrations_path
        Path[self.class._marten_app_location].join(MIGRATIONS_DIR)
      end

      # Associates a model to the current app config.
      def register_model(model : DB::Model.class)
        @models << model
      end

      # Allows to perform additional setup operations for a given application.
      #
      # Each application class can override this method in order to perform additional initializations and setup
      # operations if needed. This method will be called during the Marten setup process when all the applications
      # are known and initialized.
      def setup
      end

      # Returns the templates loader of the application.
      #
      # If the application doesn't have a dedicated templates directory, `nil` is returned.
      def templates_loader
        templates_dir = Path[self.class._marten_app_location].join(TEMPLATES_DIR)
        return unless Dir.exists?(templates_dir)
        Template::Loader::FileSystem.new(templates_dir.to_s)
      end

      # Returns the translations loader of the application.
      #
      # If the application doesn't define translations in a dedicated directory, `nil` is returned.
      def translations_loader
        locales_dir = Path[self.class._marten_app_location].join(LOCALES_DIR)
        return unless Dir.exists?(locales_dir)
        I18n::Loader::YAML.new(locales_dir.to_s)
      end

      private ASSETS_DIR     = "assets"
      private LABEL_RE       = /^[a-z_]+$/
      private LOCALES_DIR    = "locales"
      private MIGRATIONS_DIR = "migrations"
      private TEMPLATES_DIR  = "templates"
    end
  end
end
