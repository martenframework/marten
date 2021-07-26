module Marten
  module DB
    module Management
      module SchemaEditor
        # :nodoc:
        module Core
          def add_column(table : TableState, column : Column::Base) : Nil
            column_type = column_sql_for(column)
            column_definition = "#{quote(column.name)} #{column_type}"

            if column.is_a?(Column::ForeignKey)
              column_definition = prepare_foreign_key_for_new_column(table, column, column_definition)
            end

            execute("ALTER TABLE #{quote(table.name)} ADD COLUMN #{column_definition}")

            if column.index? && !column.unique?
              @deferred_statements << create_index_deferred_statement(table, [column])
            end
          end

          def add_index(table : TableState, index : Management::Index) : Nil
            execute(
              create_index_deferred_statement(
                table,
                columns: index.column_names.map { |cname| table.get_column(cname) },
                name: index.name
              ).to_s
            )
          end

          def add_unique_constraint(table : TableState, unique_constraint : Management::Constraint::Unique) : Nil
            execute(
              build_sql do |s|
                s << "ALTER TABLE #{table.name}"
                s << "ADD"
                s << unique_constraint_sql_for(unique_constraint)
              end
            )
          end

          def change_column(
            project : ProjectState,
            table : TableState,
            old_column : Column::Base,
            new_column : Column::Base
          ) : Nil
            fk_constraint_names = [] of String

            # Step 1: drop possible foreign key constraints if applicable.
            if old_column.is_a?(Column::ForeignKey)
              fk_constraint_names += @connection.introspector.foreign_key_constraint_names(table.name, old_column.name)
              fk_constraint_names.each do |constraint_name|
                execute(delete_foreign_key_constraint_statement(table, constraint_name))
              end
            end

            # Step 2: drop unique constraints if the new column is no longer unique (or if it became a primary key).
            if old_column.unique? && (!new_column.unique? || (!old_column.primary_key? && new_column.primary_key?))
              constraint_names = @connection.introspector.unique_constraint_names(table.name, old_column.name)
              constraint_names.select! { |cname| !table.unique_constraints.map(&.name).includes?(cname) }
              constraint_names.each do |cname|
                execute(remove_unique_constraint_statement(table, cname))
              end
            end

            # Step 3: drop incoming FK constraints if the field is primary key that is going to be updated.
            remake_fk_columns = (
              old_column.class != new_column.class &&
              old_column.primary_key? &&
              new_column.primary_key?
            )

            incoming_foreign_keys = project.tables.values.flat_map do |other_table|
              incoming_fk_columns = other_table.columns.select(Column::ForeignKey).select do |fk_column|
                fk_column.to_table == table.name && fk_column.to_column == old_column.name
              end

              incoming_fk_columns.map { |fk_column| {other_table, fk_column} }
            end

            if remake_fk_columns
              incoming_foreign_keys.each do |other_table, fk_column|
                constraint_names = @connection.introspector.foreign_key_constraint_names(
                  other_table.name,
                  fk_column.name
                )

                constraint_names.each do |constraint_name|
                  execute(delete_foreign_key_constraint_statement(other_table, constraint_name))
                end
              end
            end

            # Step 4: delete column index if it was previously indexed (but not unique) and if the new column is not
            # indexed or is unique.
            if old_column.index? && !old_column.unique? && (!new_column.index? || new_column.unique?)
              index_names = @connection.introspector.index_names(table.name, old_column.name)
              index_names.select! { |iname| !table.indexes.map(&.name).includes?(iname) }
              index_names.each do |iname|
                execute(remove_index_statement(table, iname))
              end
            end

            # Step 5: alter the column type if the column type changed.
            # Step 6: alter the column default value if it changed.
            # Step 7: alter the column nullability if it changed.
          end

          def create_table(table : TableState) : Nil
            definitions = [] of String

            table.columns.each do |column|
              column_type = column_sql_for(column)
              column_definition = "#{quote(column.name)} #{column_type}"

              if column.is_a?(Column::ForeignKey)
                column_definition = prepare_foreign_key_for_new_table(table, column, column_definition)
              end

              definitions << column_definition
            end

            table.unique_constraints.each do |unique_constraint|
              definitions << unique_constraint_sql_for(unique_constraint)
            end

            execute(create_table_statement(table.name, definitions.join(", ")))

            # Forwards indexes configured as part of specific columns and the corresponding SQL statements to the array
            # of deferred SQL statements.
            table.columns.each do |column|
              next if !column.index? || column.unique?
              @deferred_statements << create_index_deferred_statement(table, [column])
            end

            # Forwards custom indexes (indexes targetting multiple columns) to the array of deferred SQL statements.
            table.indexes.each do |index|
              @deferred_statements << create_index_deferred_statement(
                table,
                columns: index.column_names.map { |cname| table.get_column(cname) },
                name: index.name
              )
            end
          end

          def delete_table(name : String) : Nil
            execute(delete_table_statement(name))

            # Removes all deferred statements that still reference the deleted table.
            @deferred_statements.reject! { |s| s.references_table?(name) }
          end

          def flush_tables(table_names : Array(String)) : Nil
            flush_statements = flush_tables_statements(table_names)
            @connection.open do |db|
              flush_statements.each do |sql|
                db.exec(sql)
              end
            end
          end

          def remove_column(table : TableState, column : Column::Base) : Nil
            # First drops possible foreign key constraints if applicable.
            fk_constraint_names = @connection.introspector.foreign_key_constraint_names(table.name, column.name)
            fk_constraint_names.each do |constraint_name|
              execute(delete_foreign_key_constraint_statement(table, constraint_name))
            end

            # Now drops the column.
            execute(delete_column_statement(table, column))

            # Removes all deferred statements that still reference the deleted column.
            @deferred_statements.reject! { |s| s.references_column?(table.name, column.name) }
          end

          def remove_index(table : TableState, index : Management::Index) : Nil
            execute(remove_index_statement(table, index))
          end

          def remove_unique_constraint(table : TableState, unique_constraint : Management::Constraint::Unique) : Nil
            execute(remove_unique_constraint_statement(table, unique_constraint))
          end

          def rename_column(table : TableState, column : Column::Base, new_name : String)
            execute(rename_column_statement(table, column, new_name))
            @deferred_statements.each do |statement|
              statement.rename_column(table.name, column.name, new_name)
            end
          end

          def rename_table(table : TableState, new_name : String) : Nil
            execute(rename_table_statement(table.name, new_name))
            @deferred_statements.each do |statement|
              statement.rename_table(table.name, new_name)
            end
          end

          private def create_index_deferred_statement(
            table : TableState,
            columns : Array(Column::Base),
            name : String? = nil
          ) : Statement
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private def column_sql_for(column)
            sql = column.sql_type(@connection)
            suffix = column.sql_type_suffix(@connection)

            if !column.default.nil?
              sql += " DEFAULT #{column.sql_quoted_default_value(@connection)}"
            end

            sql += column.null? ? " NULL" : " NOT NULL"

            if column.primary_key?
              sql += " PRIMARY KEY"
            elsif column.unique?
              sql += " UNIQUE"
            end

            sql += " #{suffix}" unless suffix.nil?

            sql
          end

          private def create_table_statement(table_name : String, definitions : String) : String
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private def delete_column_statement(table : TableState, column : Column::Base) : String
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private def delete_foreign_key_constraint_statement(table : TableState, name : String) : String
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private def delete_table_statement(table_name : String) : String
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private def flush_tables_statements(table_names : Array(String)) : Array(String)
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private def prepare_foreign_key_for_new_column(
            table : TableState,
            column : Column::ForeignKey,
            column_definition : String
          ) : String
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private def prepare_foreign_key_for_new_table(
            table : TableState,
            column : Column::ForeignKey,
            column_definition : String
          ) : String
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private def remove_index_statement(table : TableState, name : String) : String
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private def remove_index_statement(table : TableState, index : Management::Index) : String
            remove_index_statement(table, index.name)
          end

          private def remove_unique_constraint_statement(table : TableState, name : String) : String
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private def remove_unique_constraint_statement(
            table : TableState,
            unique_constraint : Management::Constraint::Unique
          ) : String
            remove_unique_constraint_statement(table, unique_constraint.name)
          end

          private def rename_column_statement(table : TableState, column : Column::Base, new_name : String) : String
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private def rename_table_statement(old_name : String, new_name : String) : String
            raise NotImplementedError.new("Should be implemented by subclasses")
          end

          private def unique_constraint_sql_for(unique_constraint)
            String.build do |s|
              s << "CONSTRAINT #{unique_constraint.name} "
              s << "UNIQUE "
              s << "("
              s << unique_constraint.column_names.join(", ") { |cname| quote(cname) }
              s << ")"
            end
          end
        end
      end
    end
  end
end
