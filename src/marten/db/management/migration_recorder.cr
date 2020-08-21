module Marten
  module DB
    module Management
      class MigrationRecorder
        @introspector : Introspector::Base?
        @schema_editor : SchemaEditor::Base?

        def initialize(@connection : Connection::Base)
        end

        def setup
          schema_editor.create_model(MigrationRecord) unless record_table_exist?
        end

        private def introspector
          @introspector ||= Introspector.for(@connection).not_nil!
        end

        private def schema_editor
          @schema_editor ||= SchemaEditor.for(@connection).not_nil!
        end

        private def record_table_exist?
          introspector.table_names.includes?(MigrationRecord.table_name)
        end
      end
    end
  end
end
