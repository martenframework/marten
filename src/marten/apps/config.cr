module Marten
  module Apps
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

      # Returns the translations loader of the application.
      #
      # If the application doesn't define translations in a dedicated directory, `nil` is returned.
      def translations_loader
        locales_dir = Path[self.class._marten_app_location].join(LOCALES_DIR)
        return unless Dir.exists?(locales_dir)
        I18n::Loader::YAML.new(locales_dir.to_s)
      end

      private LABEL_RE    = /^[a-z_]+$/
      private LOCALES_DIR = "locales"
    end
  end
end
