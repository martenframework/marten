module Marten
  module DB
    module Connection
      class SQLite < Base
        def column_type_for_built_in_column(id)
          BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING[id]
        end

        def column_type_suffix_for_built_in_column(id)
          BUILT_IN_COLUMN_TO_DB_TYPE_SUFFIX_MAPPING[id]?
        end

        def insert(table_name : String, values : Hash(String, ::DB::Any), pk_field_to_fetch : String? = nil) : Int64?
          column_names = values.keys.map { |column_name| "#{quote(column_name)}" }.join(", ")
          numbered_values = values.keys.map_with_index { |_c, i| parameter_id_for_ordered_argument(i + 1) }.join(", ")
          statement = "INSERT INTO #{quote(table_name)} (#{column_names}) VALUES (#{numbered_values})"

          new_record_id = nil

          open do |db|
            db.exec(statement, args: values.values)
            new_record_id = unless pk_field_to_fetch.nil?
              db.scalar("SELECT LAST_INSERT_ROWID()").as(Int32 | Int64).to_i64
            end
          end

          new_record_id
        end

        def introspector : Management::Introspector::Base
          Management::Introspector::SQLite.new(self)
        end

        def left_operand_for(id : String, _predicate) : String
          id
        end

        def operator_for(predicate) : String
          PREDICATE_TO_OPERATOR_MAPPING[predicate]
        end

        def parameter_id_for_ordered_argument(number : Int) : String
          "?"
        end

        def quote_char : Char
          '"'
        end

        def schema_editor : Management::SchemaEditor::Base
          Management::SchemaEditor::SQLite.new(self)
        end

        def scheme : String
          "sqlite3"
        end

        def update(
          table_name : String,
          values : Hash(String, ::DB::Any),
          pk_column_name : String,
          pk_value : ::DB::Any
        ) : Nil
          column_names = values.keys.map_with_index do |column_name, i|
            "#{quote(column_name)}=#{parameter_id_for_ordered_argument(i + 1)}"
          end.join(", ")

          statement = "UPDATE #{quote(table_name)} SET #{column_names} " \
                      "WHERE #{quote(pk_column_name)}=#{parameter_id_for_ordered_argument(values.size + 1)}"

          open do |db|
            db.exec(statement, args: values.values + [pk_value])
          end
        end

        protected def build_url
          super.gsub(IN_MEMORY_ID, "")
        end

        private BUILT_IN_COLUMN_TO_DB_TYPE_MAPPING = {
          "Marten::DB::Migration::Column::Auto"       => "integer",
          "Marten::DB::Migration::Column::BigAuto"    => "integer",
          "Marten::DB::Migration::Column::BigInt"     => "integer",
          "Marten::DB::Migration::Column::Bool"       => "bool",
          "Marten::DB::Migration::Column::DateTime"   => "datetime",
          "Marten::DB::Migration::Column::ForeignKey" => "integer",
          "Marten::DB::Migration::Column::Int"        => "integer",
          "Marten::DB::Migration::Column::String"     => "varchar(%{max_size})",
          "Marten::DB::Migration::Column::Text"       => "text",
          "Marten::DB::Migration::Column::UUID"       => "char(32)",
        }

        private BUILT_IN_COLUMN_TO_DB_TYPE_SUFFIX_MAPPING = {
          "Marten::DB::Migration::Column::Auto"    => "AUTOINCREMENT",
          "Marten::DB::Migration::Column::BigAuto" => "AUTOINCREMENT",
        }

        private PREDICATE_TO_OPERATOR_MAPPING = {
          "contains"    => "LIKE %s ESCAPE '\\'",
          "endswith":      "LIKE %s ESCAPE '\\'",
          "exact"       => "= %s",
          "icontains"   => "LIKE %s ESCAPE '\\'",
          "iendswith":     "LIKE %s ESCAPE '\\'",
          "iexact"      => "LIKE %s ESCAPE '\\'",
          "istartswith" => "LIKE %s ESCAPE '\\'",
          "startswith"  => "LIKE %s ESCAPE '\\'",
        }
      end

      private IN_MEMORY_ID = ":memory:"
    end
  end
end
