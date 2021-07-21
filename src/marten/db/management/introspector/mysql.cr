module Marten
  module DB
    module Management
      module Introspector
        class MySQL < Base
          def get_foreign_key_constraint_names_statement(table_name : String, column_name : String) : String
            build_sql do |s|
              s << "SELECT c.constraint_name"
              s << "FROM information_schema.key_column_usage AS c"
              s << "WHERE c.table_schema = DATABASE() AND c.table_name = '#{table_name}'"
              s << "AND c.column_name = '#{column_name}'"
              s << "AND c.referenced_column_name IS NOT NULL"
            end
          end

          def get_unique_constraint_names_statement(table_name : String, column_name : String) : String
            build_sql do |s|
              s << "SELECT kc.constraint_name"
              s << "FROM information_schema.key_column_usage AS kc, "
              s << "information_schema.table_constraints AS c"
              s << "WHERE kc.table_schema = DATABASE() AND kc.table_name = '#{table_name}'"
              s << "AND kc.column_name = '#{column_name}'"
              s << "AND c.table_schema = kc.table_schema"
              s << "AND c.table_name = kc.table_name"
              s << "AND c.constraint_name = kc.constraint_name"
              s << "AND (c.constraint_type = 'PRIMARY KEY' OR c.constraint_type = 'UNIQUE')"
            end
          end

          def list_table_names_statement : String
            "SHOW TABLES"
          end
        end
      end
    end
  end
end
