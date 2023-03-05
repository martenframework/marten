module Marten
  module DB
    module Connection
      class MySQL < Base
        def distinct_clause_for(columns : Array(String)) : String
          return DISTINCT_CLAUSE if columns.empty?
          raise NotImplementedError.new("DISTINCT ON columns is not supported by this connection implementation")
        end

        def insert(table_name : String, values : Hash(String, ::DB::Any), pk_field_to_fetch : String? = nil) : ::DB::Any
          column_names = values.keys.join(", ") { |column_name| "#{quote(column_name)}" }
          numbered_values = values.keys.map_with_index { |_c, i| parameter_id_for_ordered_argument(i + 1) }.join(", ")
          statement = "INSERT INTO #{quote(table_name)} (#{column_names}) VALUES (#{numbered_values})"

          new_record_id = nil

          open do |db|
            db.exec(statement, args: values.values)
            new_record_id = unless pk_field_to_fetch.nil?
              db.scalar("SELECT LAST_INSERT_ID()").as(::DB::Any)
            end
          end

          new_record_id
        end

        def left_operand_for(id : String, predicate) : String
          id
        end

        def limit_value(value : Int | Nil) : Int32 | Int64 | Nil | UInt32 | UInt64
          if value.nil?
            18_446_744_073_709_551_615_u64 # 2**64 - 1
          else
            value
          end
        end

        def max_name_size : Int32
          64
        end

        def operator_for(predicate) : String
          PREDICATE_TO_OPERATOR_MAPPING[predicate]
        end

        def parameter_id_for_ordered_argument(number : Int) : String
          "?"
        end

        def quote_char : Char
          '`'
        end

        def scheme : String
          "mysql"
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

        private DISTINCT_CLAUSE = "DISTINCT"

        private PREDICATE_TO_OPERATOR_MAPPING = {
          "contains"    => "LIKE BINARY %s",
          "endswith"    => "LIKE BINARY %s",
          "exact"       => "= %s",
          "gt"          => "> %s",
          "gte"         => ">= %s",
          "icontains"   => "LIKE %s",
          "iendswith"   => "LIKE %s",
          "iexact"      => "LIKE %s",
          "istartswith" => "LIKE %s",
          "lt"          => "< %s",
          "lte"         => "<= %s",
          "startswith"  => "LIKE BINARY %s",
        }
      end
    end
  end
end
