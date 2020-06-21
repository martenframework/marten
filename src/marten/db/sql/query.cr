module Marten
  module DB
    module SQL
      class Query(Model)
        def initialize
        end

        def execute : Array(Model)
          execute_query(build_query)
        end

        def first : Model
          execute_query(build_first_query).first
        end

        def exists? : Bool
          Model.connection.open do |db|
            result = db.scalar(build_exists_query)
            result.to_s == "1"
          end
        end

        def count
          Model.connection.open do |db|
            result = db.scalar(build_count_query)
            result.to_s.to_i
          end
        end

        protected def clone
          cloned = self.class.new
          cloned
        end

        private def execute_query(query)
          results = [] of Model

          Model.connection.open do |db|
            db.query query do |result_set|
              result_set.each { results << Model.from_db_result_set(result_set) }
            end
          end

          results
        end

        private def build_query
          build_sql do |s|
            s << "SELECT #{columns}"
            s << "FROM #{table_name}"
          end
        end

        private def build_first_query
          build_sql do |s|
            s << "SELECT #{columns}"
            s << "FROM #{table_name}"
            s << "LIMIT 1"
          end
        end

        private def build_exists_query
          build_sql do |s|
            s << "SELECT EXISTS("
            s << "  SELECT 1 FROM #{table_name}"
            s << ")"
          end
        end

        private def build_count_query
          build_sql do |s|
            s << "SELECT COUNT(*)"
            s << "FROM #{table_name}"
          end
        end

        private def build_sql
          yield (clauses = [] of String?)
          clauses.compact!.join " "
        end

        private def table_name
          Model.connection.quote(Model.table_name)
        end

        private def columns
          Model.fields.map(&.id).flatten.join(", ")
        end
      end
    end
  end
end
