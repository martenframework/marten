module Marten
  module DB
    module Query
      module SQL
        class Query(Model)
          @default_ordering = true
          @distinct = false
          @distinct_columns = [] of String
          @joins = [] of Join
          @limit = nil
          @offset = nil
          @order_clauses = [] of {String, Bool}
          @predicate_node = nil
          @using = nil

          getter default_ordering
          getter distinct
          getter distinct_columns
          getter joins
          getter limit
          getter offset
          getter order_clauses
          getter predicate_node
          getter using

          setter default_ordering
          setter distinct
          setter using

          # :nodoc:
          delegate build_sql, to: connection
          delegate quote, to: connection

          def initialize
          end

          def initialize(
            @default_ordering : Bool,
            @distinct : Bool,
            @distinct_columns : Array(String),
            @joins : Array(Join),
            @limit : Int64?,
            @offset : Int64?,
            @order_clauses : Array({String, Bool}),
            @predicate_node : PredicateNode?,
            @using : String?
          )
          end

          def add_query_node(query_node : Node)
            predicate_node = process_query_node(query_node)
            @predicate_node ||= PredicateNode.new
            @predicate_node.not_nil!.add(predicate_node, PredicateConnector::AND)
          end

          def add_selected_join(relation : String) : Nil
            ensure_join_for_field_path(
              verify_field(relation, only_relations: true, allow_reverse_relations: false),
              selected: true
            )
          end

          def clone
            self.class.new(
              default_ordering: @default_ordering,
              distinct: @distinct,
              distinct_columns: @distinct_columns,
              joins: @joins,
              limit: @limit,
              offset: @offset,
              order_clauses: @order_clauses,
              predicate_node: @predicate_node.nil? ? nil : @predicate_node.clone,
              using: @using
            )
          end

          def connection
            @using.nil? ? Model.connection : Connection.get(@using.not_nil!)
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
              ["1", "t", "true"].includes?(result.to_s)
            end
          end

          def joins?
            !@joins.empty?
          end

          def order(*fields : String) : Nil
            order(fields.to_a)
          end

          def order(fields : Array(String | Symbol)) : Nil
            order_clauses = [] of {String, Bool}

            fields.map(&.to_s).each do |raw_field|
              reversed = raw_field.starts_with?('-')
              raw_field = raw_field[1..] if reversed

              field_path = verify_field(raw_field)
              relation_field_path = field_path.select { |field, _r| field.relation? }

              if relation_field_path.empty? || field_path.size == 1
                column = "#{Model.db_table}.#{field_path.first[0].db_column!}"
              else
                join = ensure_join_for_field_path(relation_field_path)
                column = join.not_nil!.column_name(field_path.last[0].db_column!)
              end

              order_clauses << {column, reversed}
            end

            @order_clauses = order_clauses
          end

          def ordered?
            !@order_clauses.empty?
          end

          def pluck(fields : Array(String)) : Array(Array(Field::Any))
            plucked_columns = solve_plucked_columns(fields)
            execute_pluck_query(*build_pluck_query(plucked_columns), plucked_columns)
          end

          def raw_delete
            sql, parameters = build_delete_query
            connection.open do |db|
              result = db.exec(sql, args: parameters)
              result.rows_affected
            end
          end

          def setup_distinct_clause(fields : Array(String) | Nil = nil) : Nil
            self.distinct = true

            distinct_columns = [] of String

            if !fields.nil?
              fields.each do |raw_field|
                field_path = verify_field(raw_field)
                relation_field_path = field_path.select { |field, _r| field.relation? }

                if relation_field_path.empty? || field_path.size == 1
                  column = "#{Model.db_table}.#{field_path.first[0].db_column!}"
                else
                  join = ensure_join_for_field_path(relation_field_path)
                  column = join.not_nil!.column_name(field_path.last[0].db_column!)
                end

                distinct_columns << column
              end
            end

            @distinct = true
            @distinct_columns = distinct_columns
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
            else
              new_limit = (@offset.not_nil! + @limit.not_nil!) - new_offset
            end

            @offset = new_offset
            @limit = new_limit
          end

          def sliced?
            !(@limit.nil? && @offset.nil?)
          end

          def to_empty
            EmptyQuery(Model).new(
              default_ordering: @default_ordering,
              distinct: @distinct,
              distinct_columns: @distinct_columns,
              joins: @joins,
              limit: @limit,
              offset: @offset,
              order_clauses: @order_clauses,
              predicate_node: @predicate_node.nil? ? nil : @predicate_node.clone,
              using: @using
            )
          end

          def update_with(values : Hash(String | Symbol, Field::Any | DB::Model))
            values_to_update = Hash(String, ::DB::Any).new

            values.each do |name, value|
              field = get_relation_field(name, Model, silent: true) || get_field(name, Model)
              next unless field.db_column?

              if value.is_a?(DB::Model) && !value.persisted?
                raise Errors::UnexpectedFieldValue.new("#{value} is not persisted and cannot be used in update queries")
              end

              values_to_update[field.db_column!] = case value
                                                   when Field::Any
                                                     field.to_db(value)
                                                   when DB::Model
                                                     Model.pk_field.to_db(value.pk)
                                                   end
            end

            sql, parameters = build_update_query(values_to_update)
            connection.open do |db|
              result = db.exec(sql, args: parameters)
              result.rows_affected
            end
          end

          private def build_count_query
            where, parameters = where_clause_and_parameters
            limit = connection.limit_value(@limit)

            sql = build_sql do |s|
              s << "SELECT COUNT(*)"
              s << "FROM ("
              s << "SELECT"

              if distinct
                s << connection.distinct_clause_for(distinct_columns)
                s << columns
              else
                s << "#{Model.db_table}.#{Model.pk_field.db_column!}"
              end

              s << "FROM #{table_name}"
              s << @joins.join(" ", &.to_sql)
              s << where
              s << "LIMIT #{limit}" unless limit.nil?
              s << "OFFSET #{@offset}" unless @offset.nil?
              s << ") subquery"
            end

            {sql, parameters}
          end

          private def build_delete_query
            where, parameters = where_clause_and_parameters

            sql = build_sql do |s|
              s << "DELETE"
              s << "FROM #{table_name}"

              if @joins.empty?
                s << where
              else
                # If the filters involve joins we are forced to rely on a subquery in order to fetch the IDs of the
                # records to delete. Actually we even rely on subquery that fetches everything from an extra subquery in
                # order to overcome the fact that MySQL doesn't allow to reference tables that are being updated or
                # deleted within a subquery.
                s << "WHERE #{Model.db_table}.#{Model.pk_field.db_column!} IN ("
                s << "  SELECT * FROM ("
                s << "    SELECT DISTINCT #{Model.db_table}.#{Model.pk_field.db_column!}"
                s << "    FROM #{table_name}"
                s << @joins.join(" ", &.to_sql)
                s << where
                s << "  ) subquery"
                s << ")"
              end
            end

            # Note: we are not using limit/offset here because it should not be possible to delete using a sliced
            # queryset (this is actually explicitly prevented).

            {sql, parameters}
          end

          private def build_exists_query
            where, parameters = where_clause_and_parameters
            limit = connection.limit_value(@limit)

            sql = build_sql do |s|
              s << "SELECT EXISTS("
              s << "SELECT 1 FROM #{table_name}"
              s << @joins.join(" ", &.to_sql)
              s << where
              s << "LIMIT #{limit}" unless limit.nil?
              s << "OFFSET #{@offset}" unless @offset.nil?
              s << ")"
            end

            {sql, parameters}
          end

          private def build_pluck_query(plucked_columns)
            where, parameters = where_clause_and_parameters
            limit = connection.limit_value(@limit)

            sql = build_sql do |s|
              s << "SELECT"
              s << connection.distinct_clause_for(distinct_columns) if distinct
              s << plucked_columns.map(&.last).join(", ")
              s << "FROM #{table_name}"
              s << @joins.join(" ", &.to_sql)
              s << where
              s << order_by
              s << "LIMIT #{limit}" unless limit.nil?
              s << "OFFSET #{@offset}" unless @offset.nil?
            end

            {sql, parameters}
          end

          private def build_query
            where, parameters = where_clause_and_parameters
            limit = connection.limit_value(@limit)

            sql = build_sql do |s|
              s << "SELECT"
              s << connection.distinct_clause_for(distinct_columns) if distinct
              s << columns
              s << "FROM #{table_name}"
              s << @joins.join(" ", &.to_sql)
              s << where
              s << order_by
              s << "LIMIT #{limit}" unless limit.nil?
              s << "OFFSET #{@offset}" unless @offset.nil?
            end

            {sql, parameters}
          end

          private def build_update_query(values)
            where, where_parameters = where_clause_and_parameters(offset: values.size)

            column_names = values.keys.map_with_index do |column_name, i|
              "#{quote(column_name)}=#{connection.parameter_id_for_ordered_argument(i + 1)}"
            end.join(", ")

            final_parameters = values.values
            final_parameters += where_parameters if !where_parameters.nil?

            sql = if !where_parameters.nil? && !@joins.empty?
                    # Construct an update query involving subqueries in order to counteract the fact that we have to
                    # rely on joined tables. The extra subquery is necessary because MySQL doesn't allow to reference
                    # update tables in a where clause.
                    build_sql do |s|
                      s << "UPDATE"
                      s << table_name
                      s << "SET #{column_names}"
                      s << "WHERE #{Model.db_table}.#{Model.pk_field.db_column!} IN ("
                      s << "  SELECT * FROM ("
                      s << "    SELECT DISTINCT #{Model.db_table}.#{Model.pk_field.db_column!}"
                      s << "    FROM #{table_name}"
                      s << @joins.join(" ", &.to_sql)
                      s << where
                      s << "  ) subquery"
                      s << ")"
                    end
                  else
                    build_sql do |s|
                      s << "UPDATE"
                      s << table_name
                      s << "SET #{column_names}"
                      s << where
                    end
                  end

            {sql, final_parameters}
          end

          private def columns
            columns = [] of String

            columns += Model.fields.compact_map do |field|
              next unless field.db_column?
              "#{Model.db_table}.#{field.db_column!}"
            end

            @joins.select(&.selected?).each { |join| columns += join.columns }

            columns.flatten.join(", ")
          end

          private def ensure_join_for_field_path(field_path, selected = false)
            model = Model
            parent_join = nil

            field_path.each do |field, reverse_relation|
              from_model = model
              from_common_field = reverse_relation.nil? ? field : model.pk_field
              to_model = reverse_relation.nil? ? field.related_model : reverse_relation.model
              to_common_field = reverse_relation.nil? ? field.related_model.pk_field : field

              # First try to find if any Join object is already created for the considered field.
              join = flattened_joins.find do |j|
                j.from_model == from_model &&
                  j.from_common_field == from_common_field &&
                  j.to_model == to_model &&
                  j.to_common_field == to_common_field
              end

              # No existing join means that we must create a new one.
              if join.nil?
                join = Join.new(
                  id: @joins.empty? ? 1 : (flattened_joins.size + 1),
                  type: field.null? || !reverse_relation.nil? ? JoinType::LEFT_OUTER : JoinType::INNER,
                  from_model: from_model,
                  from_common_field: from_common_field,
                  to_model: to_model,
                  to_common_field: to_common_field,
                  selected: selected && reverse_relation.nil?
                )

                if parent_join.nil?
                  @joins << join
                else
                  parent_join.add_child(join)
                end
              end

              model = to_model
              parent_join = join
            end

            parent_join
          end

          private def execute_pluck_query(query, parameters, plucked_columns)
            results = [] of Array(Field::Any)

            connection.open do |db|
              db.query query, args: parameters do |result_set|
                result_set.each do
                  results << plucked_columns.each_with_object(Array(Field::Any).new) do |(field, _c), plucked_values|
                    plucked_values << field.from_db_result_set(result_set)
                  end
                end
              end
            end

            results
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

          private def flattened_joins
            @joins.flat_map(&.to_a)
          end

          private def get_field(raw_field, model)
            model.get_field(raw_field.to_s)
          rescue Errors::UnknownField
            raise_invalid_field_error_with_valid_choices(raw_field, model)
          end

          private def get_relation_field(raw_relation, model, silent = false)
            model.get_relation_field(raw_relation.to_s)
          rescue Errors::UnknownField
            return nil if silent
            raise_invalid_field_error_with_valid_choices(raw_relation, model, "relation field")
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

          private def raise_invalid_field_error_with_valid_choices(raw_field, model, field_type = "field")
            valid_choices = model.fields.join(", ", &.id)
            raise Errors::InvalidField.new(
              "Unable to resolve '#{raw_field}' as a #{field_type}. Valid choices are: #{valid_choices}."
            )
          end

          private def solve_field_and_predicate(raw_query, raw_value)
            qparts = raw_query.rpartition(Constants::LOOKUP_SEP)
            raw_field = qparts[1].empty? ? qparts[2] : qparts[0]
            raw_predicate = qparts[1].empty? ? qparts[0] : qparts[2]

            begin
              field_path = verify_field(raw_query)
              raw_predicate = nil
            rescue e : Errors::InvalidField
              raise e if raw_predicate.try(&.empty?)
              field_path = verify_field(raw_field)
            end

            relation_field_path = field_path.select { |field, _r| field.relation? }

            join = unless relation_field_path.empty? || field_path.size == 1
              # Prevent the last field to generate an extra join if the last field in the predicate is a relation (which
              # is the case when a foreign key field is filtered on for example).
              relation_field_path = relation_field_path[..-2] if relation_field_path.size == field_path.size
              ensure_join_for_field_path(relation_field_path)
            end

            field = field_path.last[0]

            value = case raw_value
                    when Field::Any, Array(Field::Any)
                      raw_value
                    when DB::Model
                      raw_value.pk
                    end

            if raw_predicate.nil? && value.nil?
              predicate_klass = Predicate::IsNull
              value = true
            elsif raw_predicate.nil?
              predicate_klass = Predicate::Exact
            else
              predicate_klass = Predicate.registry.fetch(raw_predicate) do
                raise Errors::InvalidField.new("Unknown predicate type '#{raw_predicate}'")
              end
            end

            predicate_klass.new(field, value, alias_prefix: join.nil? ? Model.db_table : join.table_alias)
          end

          private def solve_plucked_columns(fields)
            fields.each_with_object([] of Tuple(Field::Base, String)) do |raw_field, plucked_columns|
              field_path = verify_field(raw_field)
              relation_field_path = field_path.select { |field, _r| field.relation? }

              if relation_field_path.empty? || field_path.size == 1
                field = field_path.first[0]
                column = "#{Model.db_table}.#{field.db_column!}"
              else
                join = ensure_join_for_field_path(relation_field_path)
                field = field_path.last[0]
                column = join.not_nil!.column_name(field.db_column!)
              end

              plucked_columns << {field, column}
            end
          end

          private def table_name
            quote(Model.db_table)
          end

          private def verify_field(raw_field, only_relations = false, allow_reverse_relations = true)
            field_path = [] of Tuple(Field::Base, Nil | ReverseRelation)

            raw_field.split(Constants::LOOKUP_SEP).each_with_index do |part, i|
              if i > 0
                # In this case we are trying to process a query field like "author__username", so we have to ensure that
                # we are considering a relation field (such as a foreign key).
                previous_field, previous_reverse_relation = field_path[i - 1]

                if previous_field.relation?
                  model = if previous_reverse_relation.nil?
                            previous_field.related_model
                          else
                            previous_reverse_relation.model
                          end
                else
                  # If the previous was not a relation, it means that we are in the presence of a query field like
                  # "firstname__lastname", which is an invalid one and does not correspond to an actual existing field.
                  raise Errors::InvalidField.new("Unable to resolve '#{raw_field}' as an existing field")
                end
              else
                model = Model
              end

              part = model.pk_field.id if part == Constants::PRIMARY_KEY_ALIAS

              reverse_relation = nil

              field = begin
                if only_relations
                  get_relation_field(part, model)
                else
                  get_relation_field(part, model, silent: true) || get_field(part, model)
                end
              rescue e : Errors::InvalidField
                raise e unless allow_reverse_relations
                reverse_relation = model.reverse_relations.find { |r| r.id == part.to_s }
                reverse_relation.nil? ? raise e : reverse_relation.not_nil!.model.get_field(reverse_relation.field_id)
              end

              field_path << {field.as(Field::Base), reverse_relation}
            end

            field_path
          end

          private def where_clause_and_parameters(offset = 0)
            if @predicate_node.nil?
              where = nil
              parameters = nil
            else
              where, parameters = @predicate_node.not_nil!.to_sql(connection)
              parameters.each_with_index do |_p, i|
                where = where % (
                  [connection.parameter_id_for_ordered_argument(offset + i + 1)] + (["%s"] * (parameters.size - i))
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
