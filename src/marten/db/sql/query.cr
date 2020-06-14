module Marten
  module DB
    module SQL
      class Query(Model)
        def initialize
        end

        def execute
          execute_query(build_query)
        end

        def first
          execute_query(build_first_query).first
        end

        def count
          Model.connection.open do |db|
            result = db.scalar(build_count_query)
            result.to_s.to_i
          end
        end

        private def execute_query(query)
          results = [] of Model

          Model.connection.open do |db|
            db.query query do |record_set|
              record_set.each { results << Model.new }
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
