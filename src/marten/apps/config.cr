module Marten
  module Apps
    abstract class Config
      @@label = "app"

      delegate label, to: self.class

      def self.label(label : String | Symbol)
        unless LABEL_RE.match(label.to_s)
          raise Errors::InvalidAppConfig.new("A label can only contain lowercase letters and underscores")
        end
        @@label = label.to_s
      end

      def self.label : String
        @@label
      end

      # :nodoc:
      # The ::dir_location method must be defined for the registry mechanism to compile when no applications are
      # installed (which means that no app configs are defined at all).
      def self.dir_location
        __DIR__
      end

      private LABEL_RE = /^[a-z_]+$/

      macro inherited
        def self.dir_location
          __DIR__
        end
      end
    end
  end
end
