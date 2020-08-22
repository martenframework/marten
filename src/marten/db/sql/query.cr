module Marten
  module DB
    module SQL
      class Query(Model)
        @default_ordering = true
        @limit = nil
        @offset = nil
        @order_clauses = [] of {String, Bool}
        @predicate_node = nil
        @using = nil

        getter default_ordering
        getter using

        setter default_ordering
        setter using

        def initialize
        end

        def initialize(
          @default_ordering : Bool,
          @limit : Int64?,
          @offset : Int64?,
          @order_clauses : Array({String, Bool}),
          @predicate_node : PredicateNode?,
          @using : String?
        )
        end

        def execute : Array(Model)
          execute_query(*build_query)
        end

        def exists? : Bool
          sql, parameters = build_exists_query
          connection.open do |db|
            result = db.scalar(sql, args: parameters)
            result.to_s == "1"
          end
        end

        def count
          sql, parameters = build_count_query
          connection.open do |db|
            result = db.scalar(sql, args: parameters)
            result.to_s.to_i
          end
        end

        def slice(from, size = nil)
          # "from' is always relative to the currently set offset, while "from" + "limit" must not go further than the
          # currently set @offset + @limit for consistency reasons.
          from = from.to_i64

          if @offset.nil?
            new_offset = from
          elsif !@limit.nil?
            new_offset = Math.min(@offset.not_nil! + from, @offset.not_nil! + @limit.not_nil!)
          else
            new_offset = @offset.not_nil! + from
          end

          new_limit = nil
          if @limit.nil?
            new_limit = size.to_i64 unless size.nil?
          elsif size.nil?
            new_limit = @limit
          else
            new_limit = (@offset.not_nil! + @limit.not_nil!) - new_offset
          end

          @offset = new_offset
          @limit = new_limit
        end

        def order(*fields : String) : Nil
          order_clauses = [] of {String, Bool}
          fields.each do |field|
            reversed = field.starts_with?('-')
            field = field[1..] if reversed
            field = Model.pk_field.id if field == Model::PRIMARY_KEY_ALIAS
            verify_field(field)
            order_clauses << {field, reversed}
          end
          @order_clauses = order_clauses
        end

        protected def add_query_node(query_node : QueryNode(Model))
          predicate_node = process_query_node(query_node)
          if @predicate_node.nil?
            @predicate_node = predicate_node
          else
            @predicate_node.not_nil!.add(predicate_node, PredicateConnector::AND)
          end
        end

        protected def clone
          cloned = self.class.new(
            default_ordering: @default_ordering,
            limit: @limit,
            offset: @offset,
            order_clauses: @order_clauses,
            predicate_node: @predicate_node.nil? ? nil : @predicate_node.clone,
            using: @using
          )
          cloned
        end

        protected def ordered?
          !@order_clauses.empty?
        end

        private def connection
          @using.nil? ? Model.connection : Connection.get(@using)
        end

        private def execute_query(query, parameters)
          results = [] of Model

          connection.open do |db|
            db.query query, args: parameters do |result_set|
              result_set.each { results << Model.from_db_result_set(result_set) }
            end
          end

          results
        end

        private def build_query
          where, parameters = where_clause_and_parameters

          sql = build_sql do |s|
            s << "SELECT #{columns}"
            s << "FROM #{table_name}"
            s << where
            s << order_by
            s << "LIMIT #{@limit}" unless @limit.nil?
            s << "OFFSET #{@offset}" unless @offset.nil?
          end

          {sql, parameters}
        end

        private def build_exists_query
          where, parameters = where_clause_and_parameters

          sql = build_sql do |s|
            s << "SELECT EXISTS("
            s << "SELECT 1 FROM #{table_name}"
            s << where
            s << "LIMIT #{@limit}" unless @limit.nil?
            s << "OFFSET #{@offset}" unless @offset.nil?
            s << ")"
          end

          {sql, parameters}
        end

        private def build_count_query
          where, parameters = where_clause_and_parameters

          sql = build_sql do |s|
            s << "SELECT COUNT(*)"
            s << "FROM #{table_name}"
            s << where
            s << "LIMIT #{@limit}" unless @limit.nil?
            s << "OFFSET #{@offset}" unless @offset.nil?
          end

          {sql, parameters}
        end

        private def order_by
          return if @order_clauses.empty?
          clauses = @order_clauses.map do |field, reversed|
            reversed ^ @default_ordering ? "#{field} ASC" : "#{field} DESC"
          end
          "ORDER BY #{clauses.join(", ")}"
        end

        private def build_sql
          yield (clauses = [] of String?)
          clauses.compact!.join " "
        end

        private def table_name
          connection.quote(Model.table_name)
        end

        private def columns
          Model.fields.map(&.db_column).flatten.join(", ")
        end

        private def where_clause_and_parameters
          if @predicate_node.nil?
            where = nil
            parameters = nil
          else
            where, parameters = @predicate_node.not_nil!.to_sql(connection)
            parameters.each_with_index do |_p, i|
              where = where % (
                [connection.parameter_id_for_ordered_argument(i + 1)] + (["%s"] * (parameters.size - i))
              )
            end
            where = "WHERE #{where}"
          end

          {where, parameters}
        end

        private def process_query_node(query_node)
          connector = query_node.connector
          predicate_node = PredicateNode.new(connector: connector, negated: query_node.negated)

          query_node.filters.each do |raw_query, raw_value|
            raw_query = raw_query.to_s
            predicate = solve_field_and_predicate(raw_query, raw_value)
            predicate_node.predicates << predicate
          end

          query_node.children.each do |child_node|
            child_node = process_query_node(child_node)
            predicate_node.add(child_node, connector)
          end

          predicate_node
        end

        private def verify_field(raw_field)
          raw_field.split(Model::LOOKUP_SEP).each_with_index do |part, i|
            raise NotImplementedError.new("Model relations are not implemented yet") if i > 0
            get_field(part)
          end
        end

        private def solve_field_and_predicate(raw_query, raw_value)
          splitted_raw_query = raw_query.split(Model::LOOKUP_SEP, 2)

          raw_field = splitted_raw_query[0]
          raw_field = Model.pk_field.id if raw_field == Model::PRIMARY_KEY_ALIAS

          raw_predicate = splitted_raw_query.size > 1 ? splitted_raw_query[1] : nil

          field = get_field(raw_field)

          if raw_predicate.nil?
            predicate_klass = Predicate::Exact
          else
            predicate_klass = Predicate.registry.fetch(raw_predicate) do
              raise Errors::UnknownField.new("Unknown predicate type '#{raw_predicate}'")
            end
          end

          predicate_klass.new(field, raw_value)
        end

        private def get_field(raw_field)
          Model.get_field(raw_field)
        rescue Errors::UnknownField
          valid_choices = Model.fields.map(&.id).join(", ")
          raise Errors::InvalidField.new(
            "Unable to resolve '#{raw_field}' as a field. Valid choices are: #{valid_choices}."
          )
        end
      end
    end
  end
end
