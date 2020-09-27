module Marten
  module DB
    module Management
      module Migrations
        class Recorder
          @introspector : Introspector::Base?
          @schema_editor : SchemaEditor::Base?

          def initialize(@connection : Connection::Base)
          end

          def setup
            schema_editor.create_model(Record) unless record_table_exist?
          end

          def applied_migrations
            record_qs
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
