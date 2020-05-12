module Marten
  module Apps
    abstract class Config
      @@name : String?

      def self.name(name : String | Symbol)
        @@name = name.to_s
      end

      def self.name : String
        raise Errors::InvalidAppConfig.new("An app name must be specified") if @@name.nil? || @@name.not_nil!.empty?
        @@name.not_nil!
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
