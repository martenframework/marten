module Marten
  module DB
    module Management
      module SchemaEditor
        abstract class Base
          def initialize(@connection : Connection::Base)
          end

          abstract def create_table_statement(table_name : String, column_definitions : String) : String
          abstract def delete_table_statement(table_name : String) : String

          def create_model(model : Model.class)
            column_definitions = [] of String

            model.fields.each do |field|
              column_type = column_sql_for_field(field)
              column_definitions << "#{@connection.quote(field.db_column)} #{column_type}"
            end

            sql = create_table_statement(@connection.quote(model.table_name), column_definitions.join(", "))

            @connection.open do |db|
              db.exec(sql)
            end
          end

          def delete_model(model : Model.class)
            sql = delete_table_statement(@connection.quote(model.table_name))
            @connection.open do |db|
              db.exec(sql)
            end
          end

          private def column_sql_for_field(field)
            sql = field.db_type(@connection)
            sql += " PRIMARY KEY" if field.primary_key?
            sql
          end
        end
      end
    end
  end
end
