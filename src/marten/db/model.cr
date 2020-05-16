module Marten
  module DB
    abstract class Model
      def self.table_name
        @@table_name ||= %{#{name.gsub("::", "_").underscore}s}
      end

      #private def self.app_config
      #  @@app_config ||= begin
      #
      #  end
      #end

      macro inherited
        def self.dir_location
          __DIR__
        end
      end
    end
  end
end
