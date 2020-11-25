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

      private LABEL_RE = /^[a-z_]+$/
    end
  end
end
