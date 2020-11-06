module Marten
  module DB
    module Query
      module SQL
        class Query(Model)
          @default_ordering = true
          @joins = [] of Join
          @limit = nil
          @offset = nil
          @order_clauses = [] of {String, Bool}
          @predicate_node = nil
          @using = nil

          getter default_ordering
          getter using

          setter default_ordering
          setter using

          # :nodoc:
          delegate build_sql, to: connection
          delegate quote, to: connection

          def initialize
          end

          def initialize(
            @default_ordering : Bool,
            @joins : Array(Join),
            @limit : Int64?,
            @offset : Int64?,
            @order_clauses : Array({String, Bool}),
            @predicate_node : PredicateNode?,
            @using : String?
          )
          end

          def count
            sql, parameters = build_count_query
            connection.open do |db|
              result = db.scalar(sql, args: parameters)
              result.to_s.to_i
            end
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

          def joins?
            !@joins.empty?
          end

          def order(*fields : String) : Nil
            order_clauses = [] of {String, Bool}

            fields.each do |raw_field|
              reversed = raw_field.starts_with?('-')
              raw_field = raw_field[1..] if reversed

              field_path = verify_field(raw_field)
              relation_field_path = field_path.select(&.relation?)

              if relation_field_path.empty? || field_path.size == 1
                column = "#{Model.db_table}.#{field_path[0].db_column}"
              else
                join = ensure_join_for_field_path(relation_field_path)
                column = join.not_nil!.column_name(field_path.last.db_column)
              end

              order_clauses << {column, reversed}
            end

            @order_clauses = order_clauses
          end

          def ordered?
            !@order_clauses.empty?
          end

          def raw_delete
            sql, parameters = build_delete_query
            connection.open do |db|
              result = db.exec(sql, args: parameters)
              result.rows_affected
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

          def sliced?
            !(@limit.nil? && @offset.nil?)
          end

          protected def add_join(relation : String) : Nil
            ensure_join_for_field_path(verify_field(relation, only_relations: true))
          end

          protected def add_query_node(query_node : Node(Model))
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
              joins: @joins,
              limit: @limit,
              offset: @offset,
              order_clauses: @order_clauses,
              predicate_node: @predicate_node.nil? ? nil : @predicate_node.clone,
              using: @using
            )
            cloned
          end

          private def build_count_query
            where, parameters = where_clause_and_parameters

            sql = build_sql do |s|
              s << "SELECT COUNT(*)"
              s << "FROM #{table_name}"
              s << @joins.map(&.to_sql).join(" ")
              s << where
              s << "LIMIT #{@limit}" unless @limit.nil?
              s << "OFFSET #{@offset}" unless @offset.nil?
            end

            {sql, parameters}
          end

          private def build_delete_query
            where, parameters = where_clause_and_parameters

            sql = build_sql do |s|
              s << "DELETE"
              s << "FROM #{table_name}"
              s << @joins.map(&.to_sql).join(" ")
              s << where
            end

            {sql, parameters}
          end

          private def build_exists_query
            where, parameters = where_clause_and_parameters

            sql = build_sql do |s|
              s << "SELECT EXISTS("
              s << "SELECT 1 FROM #{table_name}"
              s << @joins.map(&.to_sql).join(" ")
              s << where
              s << "LIMIT #{@limit}" unless @limit.nil?
              s << "OFFSET #{@offset}" unless @offset.nil?
              s << ")"
            end

            {sql, parameters}
          end

          private def build_query
            where, parameters = where_clause_and_parameters

            sql = build_sql do |s|
              s << "SELECT #{columns}"
              s << "FROM #{table_name}"
              s << @joins.map(&.to_sql).join(" ")
              s << where
              s << order_by
              s << "LIMIT #{@limit}" unless @limit.nil?
              s << "OFFSET #{@offset}" unless @offset.nil?
            end

            {sql, parameters}
          end

          private def columns
            columns = [] of String

            columns += Model.fields.map { |f| "#{Model.db_table}.#{f.db_column}" }

            @joins.each { |join| columns += join.columns }

            columns.flatten.join(", ")
          end

          private def connection
            @using.nil? ? Model.connection : Connection.get(@using.not_nil!)
          end

          private def ensure_join_for_field_path(field_path)
            model = Model
            parent_join = nil

            field_path.each do |field|
              # First try to find if any Join object is already created for the considered field.
              join = find_join_for(model, field.relation_name)

              # No existing join means that we must create a new one.
              if join.nil?
                join = Join.new(
                  @joins.empty? ? 1 : (flattened_joins.size + 1),
                  field,
                  field.null? ? JoinType::LEFT_OUTER : JoinType::INNER,
                  model
                )

                if parent_join.nil?
                  @joins << join
                else
                  parent_join.add_child(join)
                end
              end

              model = field.related_model
              parent_join = join
            end

            parent_join
          end

          private def execute_query(query, parameters)
            results = [] of Model

            connection.open do |db|
              db.query query, args: parameters do |result_set|
                result_set.each { results << Model.from_db_row_iterator(RowIterator.new(Model, result_set, @joins)) }
              end
            end

            results
          end

          private def find_join_for(model, relation_name)
            flattened_joins.find do |join|
              join.model == model && join.field.relation_name == relation_name
            end
          end

          private def flattened_joins
            @joins.map(&.to_a).flatten
          end

          private def get_field(raw_field, model)
            model.get_field(raw_field)
          rescue Errors::UnknownField
            valid_choices = model.fields.map(&.id).join(", ")
            raise Errors::InvalidField.new(
              "Unable to resolve '#{raw_field}' as a field. Valid choices are: #{valid_choices}."
            )
          end

          private def get_relation_field(raw_relation, model, silent = false)
            model.get_relation_field(raw_relation)
          rescue Errors::UnknownField
            return nil if silent
            valid_choices = model.fields.select(&.relation?).map(&.relation_name).join(", ")
            raise Errors::InvalidField.new(
              "Unable to resolve '#{raw_relation}' as a relation field. Valid choices are: #{valid_choices}."
            )
          end

          private def order_by
            return if @order_clauses.empty?
            clauses = @order_clauses.map do |field, reversed|
              reversed ^ @default_ordering ? "#{field} ASC" : "#{field} DESC"
            end
            "ORDER BY #{clauses.join(", ")}"
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

          private def solve_field_and_predicate(raw_query, raw_value)
            qparts = raw_query.rpartition(Model::LOOKUP_SEP)
            raw_field = qparts[0]
            raw_predicate = qparts[2]

            begin
              field_path = verify_field(raw_query)
              raw_predicate = nil
            rescue e : Errors::InvalidField
              raise e if raw_predicate.try(&.empty?)
              field_path = verify_field(raw_field)
            end

            relation_field_path = field_path.select(&.relation?)

            join = unless relation_field_path.empty? || field_path.size == 1
              ensure_join_for_field_path(relation_field_path)
            end

            field = field_path.last

            if raw_predicate.nil?
              predicate_klass = Predicate::Exact
            else
              predicate_klass = Predicate.registry.fetch(raw_predicate) do
                raise Errors::UnknownField.new("Unknown predicate type '#{raw_predicate}'")
              end
            end

            value : Field::Any = case raw_value
            when Field::Any
              raw_value
            when DB::Model
              raw_value.pk
            end

            predicate_klass.new(field, value, alias_prefix: join.nil? ? Model.db_table : join.table_alias)
          end

          private def table_name
            quote(Model.db_table)
          end

          private def verify_field(raw_field, only_relations = false)
            field_path = [] of Field::Base

            raw_field.split(Model::LOOKUP_SEP).each_with_index do |part, i|
              if i > 0
                # In this case we are trying to process a query field like "author__username", so we have to ensure that
                # we are considering a relation field (such as a foreign key).
                previous_field = field_path[i - 1]

                if previous_field.relation?
                  model = previous_field.related_model
                else
                  # If the previous was not a relation, it means that we are in the presence of a query field like
                  # "firstname__lastname", which is an invalid one and does not correspond to an actual existing field.
                  raise Errors::InvalidField.new("Unable to resolve '#{raw_field}' as an existing field")
                end
              else
                model = Model
              end

              part = model.pk_field.id if part == Model::PRIMARY_KEY_ALIAS

              field = if only_relations
                        get_relation_field(part, model)
                      else
                        get_relation_field(part, model, silent: true) || get_field(part, model)
                      end

              field_path << field.as(Field::Base)
            end

            field_path
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
        end
      end
    end
  end
end
