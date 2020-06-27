module Marten
  module DB
    module SQL
      class Query(Model)
        @limit = nil
        @offset = nil
        @order_clauses = [] of {String, Bool}

        def initialize(
          @limit : Int64?,
          @offset : Int64?,
          @order_clauses : Array({String, Bool}),
        )
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

        def limit=(limit)
          @limit = limit.to_i64
        end

        def offset=(offset)
          @offset = offset.to_i64
        end

        def order(*fields : String) : Nil
          order_clauses = [] of {String, Bool}
          fields.each do |field|
            reversed = field.starts_with?('-')
            field = field[1..] if reversed
            # TODO: add field validation

            order_clauses << {field, reversed}
          end
          @order_clauses = order_clauses
        end

        protected def clone
          cloned = self.class.new(
            limit: @limit,
            offset: @offset,
            order_clauses: @order_clauses
          )
          cloned
        end

        private LOOKUP_SEP = "__"

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
            s << order_by
            s << "LIMIT #{@limit}" unless @limit.nil?
            s << "OFFSET #{@offset}" unless @offset.nil?
          end
        end

        private def build_first_query
          build_sql do |s|
            s << "SELECT #{columns}"
            s << "FROM #{table_name}"
            s << order_by
            s << "LIMIT 1"
            s << "OFFSET #{@offset}" unless @offset.nil?
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

        private def order_by
          return if @order_clauses.empty?
          clauses = @order_clauses.map do |field, reversed|
            reversed ? "#{field} DESC" : "#{field} ASC"
          end
          "ORDER BY #{clauses.join(", ")}"
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
