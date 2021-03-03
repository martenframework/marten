module Marten
  module DB
    module Management
      module Migrations
        class Recorder
          @introspector : Introspector::Base?
          @schema_editor : SchemaEditor::Base?

          def initialize(@connection : Connection::Base)
          end

          def setup : Nil
            return if record_table_exist?
            schema_editor.create_table(
              TableState.new(
                app_label: "marten",
                name: Record.db_table,
                columns: Record.fields.compact_map(&.to_column)
              )
            )
          end

          def applied_migrations
            record_qs
          end

          def record(migration : Migration)
            record(migration.class.app_config.label, migration.class.migration_name)
          end

          def record(app_label : String, name : String)
            record_qs.create!(app: app_label, name: name)
          end

          def unrecord(migration : Migration)
            unrecord(migration.class.app_config.label, migration.class.migration_name)
          end

          def unrecord(app_label : String, name : String)
            record_qs.filter(app: app_label, name: name).delete(raw: true)
          end

          private def introspector
            @introspector ||= @connection.introspector
          end

          private def record_qs
            Record.using(@connection.alias)
          end

          private def record_table_exist?
            introspector.table_names.includes?(Record.db_table)
          end

          private def schema_editor
            @schema_editor ||= @connection.schema_editor
          end
        end
      end
    end
  end
end
