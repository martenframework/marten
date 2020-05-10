module Marten
  module Apps
    abstract class Config
      @@name : String?

      def self.name(name : String | Symbol)
        @@name = name.to_s
      end

      def self.name
        @@name
      end

      macro inherited
        @@path : String?

        def self.path
          @@path ||= Path[__FILE__].parent.to_s
        end
      end
    end
  end
end
