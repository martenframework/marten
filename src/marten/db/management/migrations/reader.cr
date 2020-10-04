module Marten
  module DB
    module Management
      module Migrations
        # Represents a migrations reader.
        #
        # The migration reader will process all migrations defined by the available apps and all the migrations that
        # were already applied (ie. recorded) for the existing database in order to build a corresponding directed
        # acyclic graph of migrations.
        class Reader
          @migrations_per_app_configs : Hash(Apps::Config, Array(Migration.class))?

          getter applied_migrations
          getter graph

          def initialize(@connection : Connection::Base)
            @applied_migrations = {} of String => Migration
            @graph = Graph.new
            build_graph
          end

          private def build_graph
            recorder = Recorder.new(@connection)
            defined_migrations = {} of String => Migration
            replacements = {} of String => Migration

            migrations_per_app_configs.values.flatten.each do |migration_klass|
              defined_migrations[migration_klass.id] = migration_klass.new
            end

            recorder.applied_migrations.each do |migration|
              migration_id = Migration.gen_id(migration.app, migration.name)
              @applied_migrations[migration_id] = defined_migrations[migration_id]
            end

            # Adds each migration node to the graph.
            defined_migrations.values.each do |migration|
              @graph.add_node(migration)
              replacements[migration.id] = migration unless migration.class.replaces.empty?
            end

            # Processes each migration node and adds the necessary dependency nodes that are in the same app first.
            defined_migrations.values.each do |migration|
              migration.class.depends_on.each do |parent_app_label, parent_migration_name|
                next if migration.class.app_config.label != parent_app_label
                @graph.add_dependency(migration, Migration.gen_id(parent_app_label, parent_migration_name))
              end
            end

            # Processes each migration node and adds the necessary dependency nodes that are not in the same app.
            defined_migrations.values.each do |migration|
              migration.class.depends_on.each do |parent_app_label, parent_migration_name|
                next if migration.class.app_config.label == parent_app_label
                @graph.add_dependency(migration, Migration.gen_id(parent_app_label, parent_migration_name))
              end
            end

            # Processes identified migration replacements.
            replacements.values.each do |migration|
              replacements_applied = migration.class.replacement_ids.map do |replaced_id|
                @applied_migrations.has_key?(replaced_id)
              end

              # If all the migrations that are replaced by the current migration were already applied, the current
              # migration can be marked as applied too.
              if replacements_applied.all?
                @applied_migrations[migration.id] = migration
              else
                @applied_migrations.delete(migration.id)
              end

              if replacements_applied.all? || !replacements_applied.any?
                @graph.setup_replacement(migration)
              else
                @graph.teardown_replacement(migration)
              end
            end

            @graph.ensure_acyclic_property
          end

          private def migrations_per_app_configs
            @migrations_per_app_configs ||= begin
              mapping = {} of Apps::Config => Array(Migration.class)

              Migrations.registry.each do |migration_klass|
                app = migration_klass.app_config
                if mapping.has_key?(app)
                  mapping[app] << migration_klass
                else
                  mapping[app] = [migration_klass]
                end
              end

              mapping
            end
          end
        end
      end
    end
  end
end