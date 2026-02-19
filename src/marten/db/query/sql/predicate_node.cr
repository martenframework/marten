require "./concerns/sanitizer"

module Marten
  module DB
    module Query
      module SQL
        class PredicateNode
          include Sanitizer

          alias RawPredicate = NamedTuple(predicate: String, params: Array(::DB::Any) | Hash(String, ::DB::Any))
          alias FilterPredicates = Array(Predicate::Base)

          getter children
          getter connector
          getter negated
          getter predicates

          def initialize(@children = [] of self, @connector = SQL::PredicateConnector::AND, @negated = false, *args)
            @predicates = [] of Predicate::Base
            filter_predicates.concat(args.to_a)
          end

          def initialize(
            raw_predicate : String,
            params : Array(::DB::Any) | Hash(String, ::DB::Any) = [] of ::DB::Any,
            @children = [] of self,
            @connector = SQL::PredicateConnector::AND,
            @negated = false,
          )
            @predicates = RawPredicate.new(predicate: raw_predicate, params: params)
          end

          def initialize(
            @children : Array(self),
            @connector : PredicateConnector,
            @negated : Bool,
            @predicates : RawPredicate | FilterPredicates,
          )
          end

          def ==(other : self)
            (
              (other.predicates == predicates) &&
                (other.children == children) &&
                (other.connector == connector) &&
                (other.negated == negated)
            )
          end

          def add(other : self, conn : SQL::PredicateConnector)
            return if @children.includes?(other) && !conn.xor?

            if @connector == conn
              @children << other
            else
              new_child = self.class.new(
                children: @children,
                connector: @connector,
                negated: @negated,
                predicates: @predicates
              )
              @connector = conn
              @children = [new_child, other]
            end
          end

          def clone
            self.class.new(
              children: @children.map { |c| c.clone.as(self) },
              connector: @connector,
              negated: @negated,
              predicates: @predicates.dup
            )
          end

          def contains_annotations? : Bool
            return false unless filter_predicates?

            filter_predicates.any? { |p| p.left_operand.is_a?(Annotation::Base) } ||
              children.any?(&.contains_annotations?)
          end

          def filter_predicates : FilterPredicates
            @predicates.as(FilterPredicates)
          end

          def filter_predicates? : Bool
            @predicates.is_a?(FilterPredicates)
          end

          def raw_predicate : RawPredicate
            @predicates.as(RawPredicate)
          end

          def raw_predicate? : Bool
            @predicates.is_a?(RawPredicate)
          end

          def replace_table_alias_prefix(old_vs_new_table_aliases : Hash(String, String)) : Nil
            return unless filter_predicates?

            filter_predicates.each do |p|
              next unless old_vs_new_table_aliases.has_key?(p.alias_prefix)
              p.alias_prefix = old_vs_new_table_aliases[p.alias_prefix]
            end

            @children.each { |c| c.replace_table_alias_prefix(old_vs_new_table_aliases) }
          end

          def to_sql(connection : Connection::Base)
            if filter_predicates?
              filter_predicates_to_sql(connection)
            else
              raw_predicate_to_sql(connection)
            end
          end

          private def filter_predicates_to_sql(connection : Connection::Base)
            sql_parts = [] of String
            sql_params = [] of ::DB::Any

            filter_predicates.each do |predicate|
              predicate_sql, predicate_params = predicate.to_sql(connection)
              next if predicate_sql.empty?
              sql_parts << predicate_sql
              sql_params.concat(predicate_params)
            end

            @children.each do |child|
              child_sql, child_params = child.to_sql(connection)
              next if child_sql.empty?
              sql_parts << child_sql
              sql_params.concat(child_params)
            end

            sql_string = join_sql_parts(connection, sql_parts)

            unless sql_string.empty?
              sql_string = "NOT (#{sql_string})" if @negated
              sql_string = "(#{sql_string})" if sql_parts.size > 1
            end

            {sql_string, sql_params}
          end

          private def join_sql_parts(connection : Connection::Base, sql_parts : Array(String)) : String
            if connector.xor? && !connection.supports_logical_xor?
              # Build the SUM of CASE statements
              sql = sql_parts.map do |condition|
                "CASE WHEN #{condition} THEN 1 ELSE 0 END"
              end.join(" + ")

              # Ensure that exactly one condition is true
              "(#{sql}) = 1"
            else
              sql_parts.join(" #{@connector} ")
            end
          end

          private def raw_predicate_to_sql(connection : Connection::Base)
            # Escape % characters to be not be considered
            # during formatting process
            prepared_predicate = raw_predicate[:predicate].gsub("%", "%%")

            case params = raw_predicate[:params]
            when Array(::DB::Any)
              sanitize_positional_parameters(prepared_predicate, params.as(Array(::DB::Any)))
            else
              sanitize_named_parameters(prepared_predicate, params.as(Hash(String, ::DB::Any)))
            end
          end
        end
      end
    end
  end
end
