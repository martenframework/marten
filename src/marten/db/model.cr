module Marten
  module DB
    abstract class Model
      def self.table_name
        @@table_name ||= %{#{name.gsub("::", "_").underscore}s}
      end

      macro inherited
        def self.dir_location
          __DIR__
        end
      end
    end
  end
end
