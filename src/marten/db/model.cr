module Marten
  module DB
    abstract class Model
      def self.table_name
        @@table_name ||= %{#{name.gsub("::", "_").underscore}s}
      end
    end
  end
end
