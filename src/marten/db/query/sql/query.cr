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
          @parent_model_joins : Array(Join)?
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
            @parent_model_joins : Array(Join)?,
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
            field_path = verify_field(relation, only_relations: true, allow_many: false)

            # Special case: if the last model makes use of multi table inheritance, we have to ensure that the parent
            # models are retrieved as well in order to ensure that the joined records can properly be instantiated.

            child_model = if (reverse_relation = field_path.last[1]).nil?
                            field_path.last[0].related_model
                          else
                            reverse_relation.model
                          end

            if !child_model.nil? && child_model.pk_field.relation? && !child_model.parent_models.empty?
              field_path += construct_inheritance_field_path(child_model, child_model.parent_models.last)
            end

            ensure_join_for_field_path(field_path, selected: true)
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
              parent_model_joins: @parent_model_joins,
              predicate_node: @predicate_node.nil? ? nil : @predicate_node.clone,
              using: @using
            )
          end

          def connection
            @using.nil? ? Model.connection : Connection.get(@using.not_nil!)
          end

          def count(raw_field : String? = nil)
            column_name = if !raw_field.nil?
                            solve_field_and_column(raw_field).last
                          end

            sql, parameters = build_count_query(column_name)
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
              _, column_name = solve_field_and_column(raw_field)
              order_clauses << {column_name, reversed}
            end

            @order_clauses = order_clauses
          end

          def ordered?
            !@order_clauses.empty?
          end

          def pluck(fields : Array(String)) : Array(Array(Field::Any))
            plucked_columns = solve_plucked_fields_and_columns(fields)
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
                distinct_columns << solve_field_and_column(raw_field).last
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
              parent_model_joins: @parent_model_joins,
              predicate_node: @predicate_node.nil? ? nil : @predicate_node.clone,
              using: @using
            )
          end

          def update_with(values : Hash(String | Symbol, Field::Any | DB::Model))
            values_to_update = Hash(String, ::DB::Any).new
            related_values_to_update = Hash(DB::Model.class, Hash(String | Symbol, Field::Any | DB::Model)).new

            values.each do |name, value|
              field_context = get_field_context(name, Model)
              next unless field_context.field.db_column?

              if value.is_a?(DB::Model) && !value.persisted?
                raise Errors::UnexpectedFieldValue.new("#{value} is not persisted and cannot be used in update queries")
              end

              if field_context.model == Model
                values_to_update[field_context.field.db_column!] = case value
                                                                   when Field::Any
                                                                     field_context.field.to_db(value)
                                                                   when DB::Model
                                                                     Model.pk_field.to_db(value.pk)
                                                                   end
              else
                related_values_to_update[field_context.model] ||= Hash(String | Symbol, Field::Any | DB::Model).new
                related_values_to_update[field_context.model][name] = value
              end
            end

            sql, parameters = build_update_query(values_to_update)

            rows_affected = nil

            # If related model values also need to be updated (which can be the case when attempting to update records
            # making use of multi table inheritance), then we have to fetch the IDs of the targeted records in order to
            # be able to update the related models as well.
            if !related_values_to_update.empty?
              related_plucked_pk_columns = solve_plucked_fields_and_columns([Model.pk_field.id])
              related_pks = execute_pluck_query(
                *build_pluck_query(related_plucked_pk_columns),
                related_plucked_pk_columns
              ).flatten
            end

            connection.transaction do
              # First attempts to update the current model (only if local values need to be updated).
              rows_affected = if !values_to_update.empty?
                                connection.open do |db|
                                  result = db.exec(sql, args: parameters)
                                  result.rows_affected
                                end
                              end

              # Then updates related models if necessary.
              if !related_values_to_update.empty?
                related_values_to_update.each do |model, v|
                  related_model_query = model._base_query
                  related_model_query.add_query_node(Node.new(pk__in: related_pks))
                  related_rows_affected = related_model_query.update_with(v)

                  # Only return the number of rows affected by related model updates if no local columns were updated.
                  rows_affected = related_rows_affected if rows_affected.nil?
                end
              end
            end

            rows_affected.not_nil!
          end

          private def build_count_query(column_name : String?)
            where, parameters = where_clause_and_parameters
            limit = connection.limit_value(@limit)

            sql = build_sql do |s|
              s << "SELECT COUNT(#{column_name ? column_name.split(".")[-1] : '*'})"
              s << "FROM ("
              s << "SELECT"

              if distinct
                s << connection.distinct_clause_for(distinct_columns)
                s << columns if column_name.nil?
              elsif column_name.nil?
                s << "#{Model.db_table}.#{Model.pk_field.db_column!}"
              end

              s << column_name unless column_name.nil?

              s << "FROM #{table_name}"
              s << build_joins
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
                s << build_joins
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
              s << build_joins
              s << where
              s << "LIMIT #{limit}" unless limit.nil?
              s << "OFFSET #{@offset}" unless @offset.nil?
              s << ")"
            end

            {sql, parameters}
          end

          private def build_joins
            String.build do |s|
              # Note: the order in which joins are generated is important because parent model joins are read in order
              # and before any other additional joins.
              s << (parent_model_joins + @joins).join(" ", &.to_sql)
            end
          end

          private def build_pluck_query(plucked_columns)
            where, parameters = where_clause_and_parameters
            limit = connection.limit_value(@limit)

            sql = build_sql do |s|
              s << "SELECT"
              s << connection.distinct_clause_for(distinct_columns) if distinct
              s << plucked_columns.map(&.last).join(", ")
              s << "FROM #{table_name}"
              s << build_joins
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
              s << build_joins
              s << where
              s << order_by
              s << "LIMIT #{limit}" unless limit.nil?
              s << "OFFSET #{@offset}" unless @offset.nil?
            end

            {sql, parameters}
          end

          private def build_update_query(local_values)
            where, where_parameters = where_clause_and_parameters(offset: local_values.size)

            column_names = local_values.keys.map_with_index do |column_name, i|
              "#{quote(column_name)}=#{connection.parameter_id_for_ordered_argument(i + 1)}"
            end.join(", ")

            final_parameters = local_values.values
            final_parameters += where_parameters if !where_parameters.nil?

            sql = if !where_parameters.nil? && (!@joins.empty? || !parent_model_joins.empty?)
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
                      s << build_joins
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

            columns += Model.local_fields.compact_map do |field|
              next unless field.db_column?
              "#{Model.db_table}.#{field.db_column!}"
            end

            parent_model_joins.each { |join| columns += join.columns }

            @joins.select(&.selected?).each { |join| columns += join.columns }

            columns.flatten.join(", ")
          end

          private def construct_inheritance_field_path(current_model, target_model)
            field_path = [] of Tuple(Field::Base, Nil | ReverseRelation)
            model_chain = [] of DB::Model.class

            current_model.parent_models.each do |int_model|
              model_chain << int_model

              break if int_model == target_model
            end

            model_chain.map_with_index do |_, j|
              child_model = (j == 0) ? current_model : model_chain[j - 1]
              field_path << {child_model.pk_field, nil}
            end

            field_path
          end

          private def ensure_join_for_field_path(field_path, selected = false)
            model = Model
            parent_join = nil

            field_path.each do |field, reverse_relation|
              if field.is_a?(Field::ManyToMany)
                # If we are considering a many-to-many field, we first have to create a join that goes through the
                # through model.
                through_join = Join.new(
                  id: (flattened_parent_model_joins + flattened_joins).size + 1,
                  type: JoinType::INNER,
                  from_model: model,
                  from_common_field: model.pk_field,
                  reverse_relation: nil,
                  to_model: field.through,
                  to_common_field: reverse_relation.nil? ? field.through_from_field : field.through_to_field,
                  selected: false
                )
                through_join.parent = parent_join if !parent_join.nil?

                parent_join = through_join
                @joins << parent_join

                from_model = field.through
                from_common_field = reverse_relation.nil? ? field.through_to_field : field.through_from_field
                to_model = reverse_relation.nil? ? field.related_model : reverse_relation.model
                to_common_field = reverse_relation.nil? ? field.related_model.pk_field : reverse_relation.model.pk_field
              else
                from_model = model
                from_common_field = reverse_relation.nil? ? field : model.pk_field
                to_model = reverse_relation.nil? ? field.related_model : reverse_relation.model
                to_common_field = reverse_relation.nil? ? field.related_model.pk_field : field
              end

              all_joins = flattened_parent_model_joins + flattened_joins

              # First try to find if any Join object is already created for the considered field.
              join = all_joins.find do |j|
                j.from_model == from_model &&
                  j.from_common_field == from_common_field &&
                  j.to_model == to_model &&
                  j.to_common_field == to_common_field
              end

              # No existing join means that we must create a new one.
              if join.nil?
                join = Join.new(
                  id: all_joins.size + 1,
                  type: field.null? || !reverse_relation.nil? ? JoinType::LEFT_OUTER : JoinType::INNER,
                  from_model: from_model,
                  from_common_field: from_common_field,
                  reverse_relation: reverse_relation,
                  to_model: to_model,
                  to_common_field: to_common_field,
                  selected: selected
                )

                if parent_join.nil?
                  # No parent join means that we must add the join to the top-level joins.
                  @joins << join
                elsif flattened_parent_model_joins.includes?(parent_join)
                  # If the parent join is a parent model join, we must add the join to the top-level joins as well while
                  # ensuring that the parent join is correctly set. This is because the columns that are associated to
                  # parent model joins are always selected (and read) before the columns of other joins.
                  join.parent = parent_join
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
                result_set.each do
                  results << Model.from_db_row_iterator(RowIterator.new(Model, result_set, @joins + parent_model_joins))
                end
              end
            end

            results
          end

          private def flattened_joins
            @joins.flat_map(&.to_a)
          end

          private def flattened_parent_model_joins
            parent_model_joins.flat_map(&.to_a)
          end

          private def get_field(raw_field, model)
            get_field_context(raw_field, model).field
          end

          private def get_field_context(raw_field, model, allow_many = true)
            field_context = begin
              model.get_field_context(raw_field.to_s)
            rescue Errors::UnknownField
              raise_invalid_field_error_with_valid_choices(raw_field, model, allow_many: allow_many)
            end

            if !allow_many && field_context.field.is_a?(Field::ManyToMany)
              raise_invalid_field_error_with_valid_choices(raw_field, model, allow_many: allow_many)
            end

            field_context
          end

          private def get_relation_field_context(raw_relation, model, allow_many = true, silent = false)
            field_context = begin
              model.get_relation_field_context(raw_relation.to_s)
            rescue Errors::UnknownField
              return nil if silent
              raise_invalid_field_error_with_valid_choices(
                raw_relation,
                model,
                "relation field",
                allow_many: allow_many
              )
            end

            if !allow_many && field_context.field.is_a?(Field::ManyToMany)
              raise_invalid_field_error_with_valid_choices(
                raw_relation,
                model,
                field_type: "relation field",
                allow_many: allow_many
              )
            end

            field_context
          end

          private def order_by
            return if @order_clauses.empty?
            clauses = @order_clauses.map do |field, reversed|
              reversed ^ @default_ordering ? "#{field} ASC" : "#{field} DESC"
            end
            "ORDER BY #{clauses.join(", ")}"
          end

          private def parent_model_joins
            @parent_model_joins ||= begin
              flat_joins = Model.parent_models.map_with_index do |parent_model, i|
                previous_model = (i == 0) ? Model : Model.parent_models[i - 1]
                Join.new(
                  id: i + 1,
                  type: JoinType::INNER,
                  from_model: previous_model,
                  from_common_field: previous_model.pk_field,
                  reverse_relation: nil,
                  to_model: parent_model,
                  to_common_field: parent_model.pk_field,
                  selected: true,
                  table_alias_prefix: "p"
                )
              end

              if flat_joins.empty?
                flat_joins
              else
                flat_joins[1..].each do |join|
                  flat_joins[0].add_child(join)
                end

                [flat_joins.first]
              end
            end
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

          private def raise_invalid_field_error_with_valid_choices(
            raw_field,
            model,
            field_type = "field",
            allow_many = true
          )
            fields = model.fields
            fields = fields.reject(Field::ManyToMany) if !allow_many

            raise Errors::InvalidField.new(
              "Unable to resolve '#{raw_field}' as a #{field_type}. Valid choices are: #{fields.join(", ", &.id)}."
            )
          end

          private def solve_field_and_column(raw_field)
            field_path = verify_field(raw_field.to_s, allow_many: false)
            relation_field_path = field_path.select { |field, _r| field.relation? }

            if relation_field_path.empty? || (field_path.size == 1 && field_path.last[1].nil?)
              # If we are not considering a relation field or if we are considering a direct relationship (eg. a
              # many-to-one or one-to-one field), then we can assume that the column is available on the current model.
              field = field_path.first[0]
              column = "#{Model.db_table}.#{field_path.first[0].db_column!}"
            else
              # If we are going through a relation field (or a reverse relation), we have to ensure that the necessary
              # joins are created in order to be able to access the targeted column.
              join = ensure_join_for_field_path(relation_field_path)

              # If the last field accessed is a reverse relation, we have to use the primary key of the related model as
              # the targeted field.
              field = if !(reverse_relation = field_path.last[1]).nil?
                        reverse_relation.model.pk_field
                      else
                        field_path.last[0]
                      end

              column = join.not_nil!.column_name(field.db_column!)
            end

            {field, column}
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

          private def solve_plucked_fields_and_columns(fields)
            fields.each_with_object([] of Tuple(Field::Base, String)) do |raw_field, plucked_columns|
              plucked_columns << solve_field_and_column(raw_field)
            end
          end

          private def table_name
            quote(Model.db_table)
          end

          private def verify_field(raw_field, only_relations = false, allow_many = true)
            field_path = [] of Tuple(Field::Base, Nil | ReverseRelation)

            current_model = Model

            raw_field.split(Constants::LOOKUP_SEP).each_with_index do |part, i|
              if i > 0
                # In this case we are trying to process a query field like "author__username", so we have to ensure that
                # we are considering a relation field (such as a foreign key).
                previous_field, _ = field_path[i - 1]

                if !previous_field.relation?
                  # If the previous was not a relation, it means that we are in the presence of a query field like
                  # "firstname__lastname", which is an invalid one and does not correspond to an actual existing field.
                  raise Errors::InvalidField.new("Unable to resolve '#{raw_field}' as an existing field")
                end
              end

              part = current_model.pk_field.id if part == Constants::PRIMARY_KEY_ALIAS

              reverse_relation_context = nil

              field_context = begin
                if only_relations
                  get_relation_field_context(part, current_model, allow_many: allow_many)
                else
                  get_field_context(part, current_model, allow_many: allow_many)
                end
              rescue e : Errors::InvalidField
                reverse_relation_context = current_model.get_reverse_relation_context(part.to_s)

                # If allow_many is set to false, we have to ensure that the reverse relation is a one-to-one relation.
                if reverse_relation_context.nil? || (
                     !reverse_relation_context.nil? &&
                     !allow_many &&
                     !reverse_relation_context.reverse_relation.one_to_one?
                   )
                  raise e
                else
                  reverse_relation_context.reverse_relation.model.get_field_context(
                    reverse_relation_context.reverse_relation.field_id
                  )
                end
              end

              field_context = field_context.as(DB::Model::Table::FieldContext)

              # If we are in the presence of a field or reverse relation that is not local to the current model, we have
              # to add the necessary joins in order to be able to access it. This can be the case when filtering on
              # "local" attributes that are inherited from concrete models in case of multi table inheritance scenarios.
              # To do so we first identify the actual targeted parent model (which can vary depending on whether we are
              # considering a field or a reverse relation).
              target_parent_model = if reverse_relation_context.nil? && field_context.model != current_model
                                      field_context.model
                                    elsif !reverse_relation_context.nil? &&
                                          reverse_relation_context.model != current_model
                                      reverse_relation_context.model
                                    else
                                      nil
                                    end

              # Given the identified targeted parent model, we can build a chain of models that must be joined in order
              # to reach it (and the requested field).
              if !target_parent_model.nil?
                field_path += construct_inheritance_field_path(current_model, target_parent_model)
              end

              # The current model must be set in order to be able to correctly identify the actual targeted model field
              # in the next iteration.
              if reverse_relation_context.nil? && field_context.field.relation?
                current_model = field_context.field.related_model
              elsif !reverse_relation_context.nil?
                current_model = reverse_relation_context.reverse_relation.model
              end

              field_path << {field_context.field, reverse_relation_context.try(&.reverse_relation)}
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
