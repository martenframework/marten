module Marten
  module DB
    module Connection
      class SQLite < Base
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

        def sanitize_like_pattern(pattern : String) : String
          pattern.gsub("%", "\%").gsub("_", "\_")
        end

        def scheme : String
          "sqlite3"
        end

        private PREDICATE_TO_OPERATOR_MAPPING = {
          "contains" => "LIKE %s ESCAPE '\\'",
          "endswith": "LIKE %s ESCAPE '\\'",
          "exact" => "= %s",
          "icontains" => "LIKE %s ESCAPE '\\'",
          "iendswith": "LIKE %s ESCAPE '\\'",
          "iexact" => "LIKE %s ESCAPE '\\'",
          "istartswith" => "LIKE %s ESCAPE '\\'",
          "startswith" => "LIKE %s ESCAPE '\\'",
        }
      end
    end
  end
end
