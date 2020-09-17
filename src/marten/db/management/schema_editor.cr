module Marten
  module DB
    module Management
      module SchemaEditor
        # Returns a schema editor instance for a given database connection.
        def self.for(connection : Connection::Base)
          case connection
          when Connection::PostgreSQL
            klass = PostgreSQL
          when Connection::SQLite
            klass = SQLite
          end

          klass.not_nil!.new(connection)
        end

        # Returns a schema editor instance whose SQL operations can be enclosed in a single transaction.
        #
        # By default all operations performed with the yielded schema editor object will be done inside a single
        # transaction, unless `atomic` is set to `false`. Note that some database backends (such as MySQL) may not
        # support transactions for DDL statements ; in those case the use of `atomic` will be ignored.
        def self.run_for(connection : Connection::Base, atomic = true, &block)
          editor = self.for(connection)

          if atomic && editor.ddl_rollbackable?
            connection.transaction do
              yield editor
            end
          else
            yield editor
          end
        end
      end
    end
  end
end
