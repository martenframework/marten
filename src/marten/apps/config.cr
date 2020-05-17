module Marten
  module Apps
    abstract class Config
      @@name = "app"

      delegate name, to: self.class

      def self.name(name : String | Symbol)
        unless NAME_RE.match(name.to_s)
          raise Errors::InvalidAppConfig.new("A rule name can only contain lowercase letters and underscores")
        end
        @@name = name.to_s
      end

      def self.name : String
        @@name
      end

      private NAME_RE = /^[a-z_]+$/

      macro inherited
        def self.dir_location
          __DIR__
        end
      end
    end
  end
end
