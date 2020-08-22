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

          private def introspector
            @introspector ||= Introspector.for(@connection).not_nil!
          end

          private def schema_editor
            @schema_editor ||= SchemaEditor.for(@connection).not_nil!
          end

          private def record_table_exist?
            introspector.table_names.includes?(Record.table_name)
          end
        end
      end
    end
  end
end
