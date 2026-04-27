module Marten
  module DB
    module Connection
      class SQLite < Base
        def bulk_batch_size(records_count : Int32, values_count : Int32) : Int32
          if values_count == 1
            500
          elsif values_count > 1
            999 // values_count
          else
            records_count
          end
        end

        def bulk_insert(
          table_name : String,
          values : Array(Hash(String, ::DB::Any)),
          pk_column_to_fetch : String? = nil,
        ) : Array(::DB::Any)?
          column_names = values[0].keys.join(", ") { |column_name| "#{quote(column_name)}" }

          index = 0
          numbered_values = values.map do |raw_values|
            raw_values.keys.map do |_c|
              index += 1
              parameter_id_for_ordered_argument(index)
            end.join(", ")
          end

          statement = "INSERT INTO #{quote(table_name)} (#{column_names}) " \
                      "VALUES #{numbered_values.map { |v| "(#{v})" }.join(", ")}"
          statement += " RETURNING #{quote(pk_column_to_fetch)}" unless pk_column_to_fetch.nil?

          new_record_ids = nil

          open do |db|
            if pk_column_to_fetch
              new_record_ids = [] of ::DB::Any
              db.query(statement, args: values.flat_map(&.values)) do |result_set|
                result_set.each do
                  new_record_ids << result_set.read(::DB::Any)
                end
              end
            else
              db.exec(statement, args: values.flat_map(&.values))
            end
          end

          new_record_ids
        end

        def distinct_clause_for(columns : Array(String)) : String
          return DISTINCT_CLAUSE if columns.empty?
          raise NotImplementedError.new("DISTINCT ON columns is not supported by this connection implementation")
        end

        def insert(
          table_name : String,
          values : Hash(String, ::DB::Any),
          pk_column_to_fetch : String? = nil,
        ) : ::DB::Any
          column_names = values.keys.join(", ") { |column_name| "#{quote(column_name)}" }
          numbered_values = values.keys.map_with_index { |_c, i| parameter_id_for_ordered_argument(i + 1) }.join(", ")
          statement = "INSERT INTO #{quote(table_name)} (#{column_names}) VALUES (#{numbered_values})"

          new_record_id = nil

          open do |db|
            db.exec(statement, args: values.values)
            new_record_id = unless pk_column_to_fetch.nil?
              db.scalar("SELECT LAST_INSERT_ROWID()").as(::DB::Any)
            end
          end

          new_record_id
        end

        def left_operand_for(id : String, predicate) : String
          transformation = PREDICATE_TO_LEFT_OPERAND_TRANSFORMATION_MAPPING.fetch(predicate, nil)
          transformation.nil? ? id : (transformation % id)
        end

        def limit_value(value : Int | Nil) : Int32 | Int64 | Nil | UInt32 | UInt64
          value.nil? ? -1 : value
        end

        def max_name_size : Int32
          128
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

        def scheme : String
          "sqlite3"
        end

        def supports_logical_xor? : Bool
          false
        end

        def update(
          table_name : String,
          values : Hash(String, ::DB::Any),
          pk_column_name : String,
          pk_value : ::DB::Any,
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

        private DISTINCT_CLAUSE = "DISTINCT"

        private PREDICATE_TO_LEFT_OPERAND_TRANSFORMATION_MAPPING = {
          "year"   => "CAST(STRFTIME('%%Y', %s) AS INTEGER)",
          "month"  => "CAST(STRFTIME('%%m', %s) AS INTEGER)",
          "day"    => "CAST(STRFTIME('%%d', %s) AS INTEGER)",
          "hour"   => "CAST(STRFTIME('%%H', %s) AS INTEGER)",
          "minute" => "CAST(STRFTIME('%%M', %s) AS INTEGER)",
          "second" => "CAST(STRFTIME('%%S', %s) AS INTEGER)",
        }

        private PREDICATE_TO_OPERATOR_MAPPING = {
          "contains"    => "LIKE %s ESCAPE '\\'",
          "endswith"    => "LIKE %s ESCAPE '\\'",
          "exact"       => "= %s",
          "gt"          => "> %s",
          "gte"         => ">= %s",
          "icontains"   => "LIKE %s ESCAPE '\\'",
          "iendswith"   => "LIKE %s ESCAPE '\\'",
          "iexact"      => "LIKE %s ESCAPE '\\'",
          "istartswith" => "LIKE %s ESCAPE '\\'",
          "lt"          => "< %s",
          "lte"         => "<= %s",
          "startswith"  => "LIKE %s ESCAPE '\\'",
        }

        private IN_MEMORY_ID = ":memory:"
      end
    end
  end
end
