require "./schema_editor/**"

module Marten
  module DB
    module Management
      module SchemaEditor
        IMPLEMENTATIONS = {
          Connection::MYSQL_ID      => SchemaEditor::MySQL,
          Connection::POSTGRESQL_ID => SchemaEditor::PostgreSQL,
          Connection::SQLITE_ID     => SchemaEditor::SQLite,
        }

        # Returns a schema editor for the passed connection.
        def self.for(connection : Connection::Base) : SchemaEditor::Base
          IMPLEMENTATIONS[connection.id].new(connection)
        end

        # Returns a schema editor instance whose SQL operations can be enclosed in a single transaction.
        #
        # By default all operations performed with the yielded schema editor object will be done inside a single
        # transaction, unless `atomic` is set to `false`. Note that some database backends (such as MySQL) may not
        # support transactions for DDL statements ; in those case the use of `atomic` will be ignored.
        def self.run_for(connection : Connection::Base, atomic = true, &)
          editor = SchemaEditor.for(connection)

          if atomic && editor.ddl_rollbackable?
            connection.transaction do
              yield editor
              editor.execute_deferred_statements
            end
          else
            yield editor
            editor.execute_deferred_statements
          end
        end
      end
    end
  end
end
