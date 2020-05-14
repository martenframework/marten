module Marten
  module Apps
    abstract class Config
      @@name = "app"

      def self.name(name : String | Symbol)
        @@name = name.to_s
      end

      def self.name : String
        @@name
      end

      macro inherited
        def self.dir_location
          __DIR__
        end
      end
    end
  end
end
