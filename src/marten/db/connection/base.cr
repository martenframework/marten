module Marten
  module DB
    module Connection
      abstract class Base
        @db : ::DB::Database?

        def initialize(@config : Conf::GlobalSettings::Database)
        end

        abstract def scheme : String

        def db
          @db ||= ::DB.open(url)
        end

        def open(&block)
          yield db
        end

        private def url
          "#{scheme}://#{db_name}"
        end

        private def db_name
          @config.name
        end
      end
    end
  end
end
