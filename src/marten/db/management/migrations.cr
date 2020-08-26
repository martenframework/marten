module Marten
  module DB
    module Management
      module Migrations
        @@registry = [] of Migration.class

        def self.register(migration_klass : Migration.class)
          @@registry << migration_klass
        end
      end
    end
  end
end
