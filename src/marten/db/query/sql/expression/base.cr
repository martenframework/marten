module Marten
  module DB
    module Query
      module SQL
        module Expression
          abstract class Base
            abstract def to_sql_left(connection : Connection::Base, alias_prefix : String) : String

            def to_db(value : Field::Any | Array(Field::Any)) : ::DB::Any | Array(::DB::Any)
              case value
              when Array(Field::Any)
                value.map { |v| coerce_db_any(v) }
              else
                coerce_db_any(value)
              end
            end

            private def coerce_db_any(v : Field::Any) : ::DB::Any
              case v
              when Int32, Int64, Float32, Float64, String, Bool, Time, Slice(UInt8), Nil
                v
              else
                raise ::Marten::DB::Errors::UnexpectedFieldValue.new(
                  "Unsupported value type for SQL parameter: #{v.class}"
                )
              end
            end
          end
        end
      end
    end
  end
end
